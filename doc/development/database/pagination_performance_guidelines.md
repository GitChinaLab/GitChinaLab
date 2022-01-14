---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pagination performance guidelines

The following document gives a few ideas for improving the pagination (sorting) performance. These apply both on [offset](pagination_guidelines.md#offset-pagination) and [keyset](pagination_guidelines.md#keyset-pagination) paginations.

## Tie-breaker column

When ordering the columns it's advised to order by distinct columns only. Consider the following example:

|`id`|`created_at`|
|-|-|
|1|2021-01-04 14:13:43|
|2|2021-01-05 19:03:12|
|3|2021-01-05 19:03:12|

If we order by `created_at`, the result would likely depend on how the records are located on the disk.

Using the tie-breaker column is advised when the data is exposed via a well defined interface and its consumed
by an automated process, such as an API. Without the tie-breaker column, the order of the rows could change
(data is re-imported) which could cause problems that are hard to debug, such as:

- An integration comparing the rows to determine changes breaks.
- E-tag cache values change, which requires a complete re-download.

```sql
SELECT issues.* FROM issues ORDER BY created_at;
```

We can fix this by adding a second column to `ORDER BY`:

```sql
SELECT issues.* FROM issues ORDER BY created_at, id;
```

This change makes the order distinct so we have "stable" sorting.

NOTE:
To make the query efficient, we need an index covering both columns: `(created_at, id)`. The order of the columns **should match** the columns in the `ORDER BY` clause.

## Ordering by joined table column

Oftentimes, we want to order the data by a column on a joined database table. The following example orders `issues` records by the `first_mentioned_in_commit_at` metric column:

```sql
SELECT issues.* FROM issues
INNER JOIN issue_metrics on issue_metrics.issue_id=issues.id
WHERE issues.project_id = 2
ORDER BY issue_metrics.first_mentioned_in_commit_at DESC, issues.id DESC
LIMIT 20
OFFSET 0
```

With PostgreSQL version 11, the planner will first look up all issues matching the `project_id` filter and then join all `issue_metrics` rows. The ordering of rows will happen in memory. In case the joined relation is always present (1:1 relationship), the database will read `N * 2` rows where N is the number of rows matching the `project_id` filter.

For performance reasons, we should avoid mixing columns from different tables when specifying the `ORDER BY` clause.

In this particular case there is no simple way (like index creation) to improve the query. We might think that changing the `issues.id` column to `issue_metrics.issue_id` will help, however, this will likely make the query perform worse because it might force the database to process all rows in the `issue_metrics` table.

One idea to address this problem is denormalization. Adding the `project_id` column to the `issue_metrics` table will make the filtering and sorting efficient:

```sql
SELECT issues.* FROM issues
INNER JOIN issue_metrics on issue_metrics.issue_id=issues.id
WHERE issue_metrics.project_id = 2
ORDER BY issue_metrics.first_mentioned_in_commit_at DESC, issue_metrics.issue_id DESC
LIMIT 20
OFFSET 0
```

NOTE:
The query will require an index on `issue_metrics` table with the following column configuration: `(project_id, first_mentioned_in_commit_at DESC, issue_id DESC)`.

## Filtering

### By project

Filtering by a project is a very common use case since we have many features on the project level. Examples: merge requests, issues, boards, iterations.

These features will have a filter on `project_id` in their base query. Loading issues for a project:

```ruby
project = Project.find(5)

# order by internal id
issues = project.issues.order(:iid).page(1).per(20)
```

To make the base query efficient, there is usually a database index covering the `project_id` column. This significantly reduces the number of rows the database needs to scan. Without the index, the whole `issues` table would be read (full table scan) by the database.

Since `project_id` is a foreign key, we might have the following index available:

```sql
"index_issues_on_project_id" btree (project_id)
```

GitLab 13.11 has the following index definition on the `issues` table:

```sql
"index_issues_on_project_id_and_iid" UNIQUE, btree (project_id, iid)
```

This index fully covers the database query and the pagination.

### By group

Unfortunately, there is no efficient way to sort and paginate on the group level. The database query execution time will increase based on the number of records in the group.

Things get worse when group level actually means group and its subgroups. To load the first page, the database needs to look up the group hierarchy, find all projects and then look up all issues.

The main reason behind the inefficient queries on the group level is the way our database schema is designed; our core domain models are associated with a project, and projects are associated with groups. This doesn't mean that the database structure is bad, it's just in a well-normalized form that is not optimized for efficient group level queries. We might need to look into denormalization in the long term.

Example: List issues in a group

```ruby
group = Group.find(9970)

Issue.where(project_id: group.projects).order(:iid).page(1).per(20)
```

The generated SQL query:

```sql
SELECT "issues".*
FROM "issues"
WHERE "issues"."project_id" IN
    (SELECT "projects"."id"
     FROM "projects"
     WHERE "projects"."namespace_id" = 5)
ORDER BY "issues"."iid" ASC
LIMIT 20
OFFSET 0
```

The execution plan shows that we read significantly more rows than requested (20), and the rows are sorted in memory:

```plaintext
 Limit  (cost=10716.87..10716.92 rows=20 width=1300) (actual time=1472.305..1472.308 rows=20 loops=1)
   ->  Sort  (cost=10716.87..10717.03 rows=61 width=1300) (actual time=1472.303..1472.305 rows=20 loops=1)
         Sort Key: issues.iid
         Sort Method: top-N heapsort  Memory: 41kB
         ->  Nested Loop  (cost=1.00..10715.25 rows=61 width=1300) (actual time=0.215..1331.647 rows=177267 loops=1)
               ->  Index Only Scan using index_projects_on_namespace_id_and_id on projects  (cost=0.44..3.77 rows=19 width=4) (actual time=0.077..1.057 rows=270 loops=1)
                     Index Cond: (namespace_id = 9970)
                     Heap Fetches: 25
               ->  Index Scan using index_issues_on_project_id_and_iid on issues  (cost=0.56..559.28 rows=448 width=1300) (actual time=0.101..4.781 rows=657 loops=270)
                     Index Cond: (project_id = projects.id)
 Planning Time: 12.281 ms
 Execution Time: 1472.391 ms
(12 rows)
```

#### Columns in the same database table

Filtering by columns located in the same database table can be improved with an index. In case we want to support filtering by the `state_id` column, we can add the following index:

```sql
"index_issues_on_project_id_and_state_id_and_iid" UNIQUE, btree (project_id, state_id, iid)
```

Example query in Rails:

```ruby
project = Project.find(5)

# order by internal id
issues = project.issues.opened.order(:iid).page(1).per(20)
```

SQL query:

```sql
SELECT "issues".*
FROM "issues"
WHERE
  "issues"."project_id" = 5
  AND ("issues"."state_id" IN (1))
ORDER BY "issues"."iid" ASC
LIMIT 20
OFFSET 0
```

Keep in mind that the index above will not support the following project level query:

```sql
SELECT "issues".*
FROM "issues"
WHERE "issues"."project_id" = 5
ORDER BY "issues"."iid" ASC
LIMIT 20
OFFSET 0
```

#### Special case: confidential flag

In the `issues` table, we have a boolean field (`confidential`) that marks an issue confidential. This makes the issue invisible (filtered out) for non-member users.

Example SQL query:

```sql
SELECT "issues".*
FROM "issues"
WHERE "issues"."project_id" = 5
AND "issues"."confidential" = FALSE
ORDER BY "issues"."iid" ASC
LIMIT 20
OFFSET 0
```

We might be tempted to add an index on `project_id`, `confidential`, and `iid` to improve the database query, however, in this case it's probably unnecessary. Based on the data distribution in the table, confidential issues are rare. Filtering them out does not make the database query significantly slower. The database might read a few extra rows, the performance difference might not even be visible to the end-user.

On the other hand, if we would implement a special filter where we only show confidential issues, we will surely need the index. Finding 20 confidential issues might require the database to scan hundreds of rows or in the worst case, all issues in the project.

NOTE:
Be aware of the data distribution and the table access patterns (how features work) when introducing a new database index. Sampling production data might be necessary to make the right decision.

#### Columns in a different database table

Example: filtering issues in a project by an assignee

```ruby
project = Project.find(5)

project
  .issues
  .joins(:issue_assignees)
  .where(issue_assignees: { user_id: 10 })
  .order(:iid)
  .page(1)
  .per(20)
```

```sql
SELECT "issues".*
FROM "issues"
INNER JOIN "issue_assignees" ON "issue_assignees"."issue_id" = "issues"."id"
WHERE "issues"."project_id" = 5
  AND "issue_assignees"."user_id" = 10
ORDER BY "issues"."iid" ASC
LIMIT 20
OFFSET 0
```

Example database (oversimplified) execution plan:

1. The database parses the SQL query and detects the `JOIN`.
1. The database splits the query into two subqueries.
    - `SELECT "issue_assignees".* FROM "issue_assignees" WHERE "issue_assignees"."user_id" = 10`
    - `SELECT "issues".* FROM "issues" WHERE "issues"."project_id" = 5`
1. The database estimates the number of rows and the costs to run these queries.
1. The database executes the cheapest query first.
1. Using the query result, load the rows from the other table (from the other query) using the JOIN column and filter the rows further.

In this particular example, the `issue_assignees` query would likely be executed first.

Running the query in production for the GitLab project produces the following execution plan:

```plaintext
 Limit  (cost=411.20..411.21 rows=1 width=1300) (actual time=24.071..24.077 rows=20 loops=1)
   ->  Sort  (cost=411.20..411.21 rows=1 width=1300) (actual time=24.070..24.073 rows=20 loops=1)
         Sort Key: issues.iid
         Sort Method: top-N heapsort  Memory: 91kB
         ->  Nested Loop  (cost=1.00..411.19 rows=1 width=1300) (actual time=0.826..23.705 rows=190 loops=1)
               ->  Index Scan using index_issue_assignees_on_user_id on issue_assignees  (cost=0.44..81.37 rows=92 width=4) (actual time=0.741..13.202 rows=215 loops=1)
                     Index Cond: (user_id = 4156052)
               ->  Index Scan using issues_pkey on issues  (cost=0.56..3.58 rows=1 width=1300) (actual time=0.048..0.048 rows=1 loops=215)
                     Index Cond: (id = issue_assignees.issue_id)
                     Filter: (project_id = 278964)
                     Rows Removed by Filter: 0
 Planning Time: 1.141 ms
 Execution Time: 24.170 ms
(13 rows)
```

The query looks up the `assignees` first, filtered by the `user_id` (`user_id = 4156052`) and it finds 215 rows. Using that 215 rows, the database will look up the 215 associated issue rows by the primary key. Notice that the filter on the `project_id` column is not backed by an index.

In most cases, we are lucky that the joined relation will not be going to return too many rows, therefore, we will end up with a relatively efficient database query that accesses low number of rows. As the database grows, these queries might start to behave differently. Let's say the number `issue_assignees` records for a particular user is very high (millions), then this join query will not perform well, and it will likely time out.

A similar problem could be a double join, where the filter exists in the 2nd JOIN query. Example: `Issue -> LabelLink -> Label(name=bug)`.

There is no easy way to fix these problems. Denormalization of data could help significantly, however, it has also negative effects (data duplication and keeping the data up to date).

Ideas for improving the `issue_assignees` filter:

- Add `project_id` column to the `issue_assignees` table so when JOIN-ing, the extra `project_id` filter will further filter the rows. The sorting will likely happen in memory:

  ```sql
  SELECT "issues".*
  FROM "issues"
  INNER JOIN "issue_assignees" ON "issue_assignees"."issue_id" = "issues"."id"
  WHERE "issues"."project_id" = 5
    AND "issue_assignees"."user_id" = 10
    AND "issue_assignees"."project_id" = 5
  ORDER BY "issues"."iid" ASC
  LIMIT 20
  OFFSET 0
  ```

- Add the `iid` column to the `issue_assignees` table. Notice that the `ORDER BY` column is different and the `project_id` filter is gone from the `issues` table:

  ```sql
  SELECT "issues".*
  FROM "issues"
  INNER JOIN "issue_assignees" ON "issue_assignees"."issue_id" = "issues"."id"
  WHERE "issue_assignees"."user_id" = 10
    AND "issue_assignees"."project_id" = 5
  ORDER BY "issue_assignees"."iid" ASC
  LIMIT 20
  OFFSET 0
  ```

The query now performs well for any number of `issue_assignees` records, however, we pay a very high price for it:

- Two columns are duplicated which increases the database size.
- We need to keep the two columns in sync.
- We need more indexes on the `issue_assignees` table to support the query.
- The new database query is very specific to the assignee search and needs complex backend code to build it.
  - If the assignee is filtered by the user, then order by a different column, remove the `project_id` filter, etc.

NOTE:
Currently we're not doing these kinds of denormalization at GitLab.
