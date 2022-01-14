---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---
# Work items widgets

## Frontend architecture

Widgets for work items are heavily inspired by [Frontend widgets](fe_guide/widgets.md).
You can expect some differences, because work items are architecturally different from issuables.

GraphQL (Vue Apollo) constitutes the core of work items widgets' stack.

### Retrieve widget information for work items

To display a work item page, the frontend must know which widgets are available
on the work item it is attempting to display. To do so, it needs to fetch the
list of widgets, using a query like this:

```plaintext
query WorkItem($workItemId: ID!) {
  workItem(workItemId: $id) @client {
    id
    type
    widgets {
      nodes {
        type
      }
    }
  }
}
```

### GraphQL queries and mutations

GraphQL queries and mutations are work item agnostic. Work item queries and mutations
should happen at the widget level, so widgets are standalone reusable components.
The work item query and mutation should support any work item type and be dynamic.
They should allow you to query and mutate any work item attribute by specifying a widget identifier.

In this query example, the description widget uses the query and mutation to
display and update the description of any work item:

```plaintext
query {
  workItem(input: {
    workItemId: "gid://gitlab/AnyWorkItem/2207",
    widgetIdentifier: "description",
  }) {
    id
    type
    widgets {
      nodes {
        ... on DescriptionWidget {
          contentText
        }
      }
    }
  }
}

```

Mutation example:

```plaintext
mutation {
  updateWorkItem(input: {
    workItemId: "gid://gitlab/AnyWorkItem/2207",
    widgetIdentifier: "description",
    value: "the updated description"
  }) {
    workItem {
      id
      description
    }
  }
}

```

### Widget's responsibility and structure

A widget is responsible for displaying and updating a single attribute, such as
title, description, or labels. Widgets must support any type of work item.
To maximize component reusability, widgets should be field wrappers owning the
work item query and mutation of the attribute it's responsible for.

A field component is a generic and simple component. It has no knowledge of the
attribute or work item details, such as input field, date selector, or dropdown.

Widgets must be configurable to support various use cases, depending on work items.
When building widgets, use slots to provide extra context while minimizing
the use of props and injected attributes.

### Examples

We have a [dropdown field component](https://gitlab.com/gitlab-org/gitlab/-/blob/eea9ad536fa2d28ee6c09ed7d9207f803142eed7/app/assets/javascripts/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue)
for use as reference.

Any work item widget can wrap the dropdown component. The widget has knowledge of
the attribute it mutates, and owns the mutation for it. Multiple widgets can use
the same field component. For example:

- Title and description widgets use the input field component.
- Start and end date use the date selector component.
- Labels, milestones, and assignees selectors use the dropdown component.

Some frontend widgets already use the dropdown component. Use them as a reference
for work items widgets development:

- `ee/app/assets/javascripts/boards/components/assignee_select.vue`
- `ee/app/assets/javascripts/boards/components/milestone_select.vue`
