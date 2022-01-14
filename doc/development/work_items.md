---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---
# Work items and work item types

## Challenges

Issues have the potential to be a centralized hub for collaboration.
We need to accept the
fact that different issue types require different fields and different context, depending
on what job they are being used to accomplish. For example:

- A bug needs to list steps to reproduce.
- An incident needs references to stack traces and other contextual information relevant only
  to that incident.

Instead of each object type diverging into a separate model, we can standardize on an underlying
common model that we can customize with the widgets (one or more attributes) it contains.

Here are some problems with current issues usage and why we are looking into work items:

- Using labels to show issue types is cumbersome and makes reporting views more complex.
- Issue types are one of the top two use cases of labels, so it makes sense to provide first class
  support for them.
- Issues are starting to become cluttered as we add more capabilities to them, and they are not
  perfect:

  - There is no consistent pattern for how to surface relationships to other objects.
  - There is not a coherent interaction model across different types of issues because we use
    labels for this.
  - The various implementations of issue types lack flexibility and extensibility.

- Epics, issues, requirements, and others all have similar but just subtle enough
  differences in common interactions that the user needs to hold a complicated mental
  model of how they each behave.
- Issues are not extensible enough to support all of the emerging jobs they need to facilitate.
- Codebase maintainability and feature development become bigger challenges as we grow the Issue type
  beyond its core role of issue tracking into supporting the different work item types and handling
  logic and structure differences.
- New functionality is typically implemented with first class objects that import behavior from issues via
  shared concerns. This leads to duplicated effort and ultimately small differences between common interactions. This
  leads to inconsistent UX.
- Codebase maintainability and feature development becomes a bigger challenges as we grow issues
  beyond its core role of issue tracking into supporting the different types and subtle differences between them.

## Work item and work item type terms

Using the terms "issue" or "issuable" to reference the types of collaboration objects
(for example, issue, bug, feature, or epic) often creates confusion. To avoid confusion, we will use the term
work item type (WIT) when referring to the type of a collaboration object.
An instance of a WIT is a work item (WI). For example, `issue#123`, `bug#456`, `requirement#789`.

### Migration strategy

WI model will be built on top of the existing `Issue` model and we'll gradually migrate `Issue`
model code to the WI model.

One way to approach it is:

```ruby
class WorkItems::WorkItem < ApplicationRecord
  self.table_name = 'issues'

  # ... all the current issue.rb code
end

class Issue < WorkItems::WorkItem
  # Do not add code to this class add to WorkItems:WorkItem
end
```

We already use the concept of WITs within `issues` table through `issue_type`
column. There are `issue`, `incident`, and `test_case` issue types. To extend this
so that in future we can allow users to define custom WITs, we will move the
`issue_type` to a separate table: `work_item_types`. The migration process of `issue_type`
to `work_item_types` will involve creating the set of WITs for all root-level groups.

NOTE:
At first, defining a WIT will only be possible at the root-level group, which would then be inherited by sub-groups.
We will investigate the possibility of defining new WITs at sub-group levels at a later iteration.

### Introducing work_item_types table

For example, suppose there are three root-level groups with IDs: `11`, `12`, and `13`. Also,
assume the following base types: `issue: 0`, `incident: 1`, `test_case: 2`.

The respective `work_item_types` records:

| `group_id`     | `base_type` | `title`   |
| -------------- | ----------- | --------- |
| 11             | 0           | Issue     |
| 11             | 1           | Incident  |
| 11             | 2           | Test Case |
| 12             | 0           | Issue     |
| 12             | 1           | Incident  |
| 12             | 2           | Test Case |
| 13             | 0           | Issue     |
| 13             | 1           | Incident  |
| 13             | 2           | Test Case |

What we will do to achieve this:

1. Add a `work_item_type_id` column to the `issues` table.
1. Ensure we write to both `issues#issue_type` and `issues#work_item_type_id` columns for
   new or updated issues.
1. Backfill the `work_item_type_id` column to point to the `work_item_types#id` corresponding
   to issue's project root groups. For example:

   ```ruby
   issue.project.root_group.work_item_types.where(base_type: issue.issue_type).first.id.
   ```

1. After `issues#work_item_type_id` is populated, we can switch our queries from
   using `issue_type` to using `work_item_type_id`.

To introduce a new WIT there are two options:

- Follow the first step of the above process. We will still need to run a migration
  that adds a new WIT for all root-level groups to make the WIT available to
  all users. Besides a long-running migration, we'll need to
  insert several million records to `work_item_types`. This might be unwanted for users
  that do not want or need additional WITs in their workflow.
- Create an opt-in flow, so that the record in `work_item_types` for specific root-level group
  is created only when a customer opts in. However, this implies a lower discoverability
  of the newly introduced work item type.

### Work item type widgets

All WITs will share the same pool of predefined widgets and will be customized by
which widgets are active on a specific WIT. Every attribute (column or association)
will become a widget with self-encapsulated functionality regardless of the WIT it belongs to.
Because any WIT can have any widget, we only need to define which widget is active for a
specific WIT. So, after switching the type of a specific work item, we display a different set
of widgets.

### Widgets metadata

In order to customize each WIT with corresponding active widgets we will need a data
structure to map each WIT to specific widgets.

NOTE:
The exact structure of the WITs widgets metadata is still to be defined.

### Custom work item types

With the WIT widget metadata and the workflow around mapping WIT to specific
widgets, we will be able to expose custom WITs to the users. Users will be able
to create their own WITs and customize them with widgets from the predefined pool.

### Custom widgets

The end goal is to allow users to define custom widgets and use these custom
widgets on any WIT. But this is a much further iteration and requires additional
investigation to determine both data and application architecture to be used.

## Migrate requirements and epics to work item types

We'll migrate requirements and epics into work item types, with their own set
of widgets. To achieve that, we'll migrate data to the `issues` table,
and we'll keep current `requirements` and `epics` tables to be used as proxies for old references to ensure
backward compatibility with already existing references.

### Migrate requirements to work item types

Currently `Requirement` attributes are a subset of `Issue` attributes, so the migration
consists mainly of:

- Data migration.
- Keeping backwards compatibility at API levels.
- Ensuring that old references continue to work.

The migration to a different underlying data structure should be seamless to the end user.

### Migrate epics to work item types

`Epic` has some extra functionality that the `Issue` WIT does not currently have.
So, migrating epics to a work item type requires providing feature parity between the current `Epic` object and WITs.

The main missing features are:

- Get WIs to the group level. This is dependent on [Consolidate Groups and Projects](https://gitlab.com/gitlab-org/architecture/tasks/-/issues/7)
  initiative.
- A hierarchy widget: the ability to structure work items into hierarchies.
- Inherited date widget.

To avoid disrupting workflows for users who are already using epics, we will introduce a new WIT
called `Feature` that will provide feature parity with epics at the project-level. Having that combined with progress
on [Consolidate Groups and Projects](https://gitlab.com/gitlab-org/architecture/tasks/-/issues/7) front will help us
provide a smooth migration path of epics to WIT with minimal disruption to user workflow.

## Work item, work item type, and widgets roadmap

We will move towards work items, work item types, and custom widgets (CW) in an iterative process.
For a rough outline of the work ahead of us, see [epic 6033](https://gitlab.com/groups/gitlab-org/-/epics/6033).
