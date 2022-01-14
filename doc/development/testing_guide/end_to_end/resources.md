---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Resource classes in GitLab QA

Resources are primarily created using Browser UI steps, but can also be created via the API or the CLI.

A typical resource class is used to create a new resource that can be used in a single test. However, several tests can
end up creating the same kind of resource and use it in ways that mean it could have been
used by more than one test. Creating a new resource each time is not efficient. Therefore, we can also create reusable
resources that are created once and can then be used by many tests.

In the following section the content focuses on single-use resources, however it also applies to reusable resources.
Information specific to [reusable resources is detailed below](#reusable-resources).

## How to properly implement a resource class?

All non-reusable resource classes should inherit from `Resource::Base`.

There is only one mandatory method to implement to define a resource class.
This is the `#fabricate!` method, which is used to build the resource via the
browser UI. Note that you should only use [Page objects](page_objects.md) to
interact with a Web page in this method.

Here is an imaginary example:

```ruby
module QA
  module Resource
    class Shirt < Base
      attr_accessor :name

      def fabricate!
        Page::Dashboard::Index.perform do |dashboard_index|
          dashboard_index.go_to_new_shirt
        end

        Page::Shirt::New.perform do |shirt_new|
          shirt_new.set_name(name)
          shirt_new.create_shirt!
        end
      end
    end
  end
end
```

### Define API implementation

A resource class may also implement the three following methods to be able to
create the resource via the public GitLab API:

- `#api_get_path`: The `GET` path to fetch an existing resource.
- `#api_post_path`: The `POST` path to create a new resource.
- `#api_post_body`: The `POST` body (as a Ruby hash) to create a new resource.

> Be aware that many API resources are [paginated](../../../api/index.md#pagination).
> If you don't find the results you expect, check if there is more that one page of results.

Let's take the `Shirt` resource class, and add these three API methods:

```ruby
module QA
  module Resource
    class Shirt < Base
      attr_accessor :name

      def fabricate!
        # ... same as before
      end

      def api_get_path
        "/shirt/#{name}"
      end

      def api_post_path
        "/shirts"
      end

      def api_post_body
        {
          name: name
        }
      end
    end
  end
end
```

The `Project` resource is a good real example of Browser
UI and API implementations.

#### Resource attributes

A resource may need another resource to exist first. For instance, a project
needs a group to be created in.

To define a resource attribute, you can use the `attribute` method with a
block using the other resource class to fabricate the resource.

That allows access to the other resource from your resource object's
methods. You would usually use it in `#fabricate!`, `#api_get_path`,
`#api_post_path`, `#api_post_body`.

Let's take the `Shirt` resource class, and add a `project` attribute to it:

```ruby
module QA
  module Resource
    class Shirt < Base
      attr_accessor :name

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-to-create-a-shirt'
        end
      end

      def fabricate!
        project.visit!

        Page::Project::Show.perform do |project_show|
          project_show.go_to_new_shirt
        end

        Page::Shirt::New.perform do |shirt_new|
          shirt_new.set_name(name)
          shirt_new.create_shirt!
        end
      end

      def api_get_path
        "/project/#{project.path}/shirt/#{name}"
      end

      def api_post_path
        "/project/#{project.path}/shirts"
      end

      def api_post_body
        {
          name: name
        }
      end
    end
  end
end
```

**Note that all the attributes are lazily constructed. This means if you want
a specific attribute to be fabricated first, you must call the
attribute method first even if you're not using it.**

#### Product data attributes

Once created, you may want to populate a resource with attributes that can be
found in the Web page, or in the API response.
For instance, once you create a project, you may want to store its repository
SSH URL as an attribute.

Again we could use the `attribute` method with a block, using a page object
to retrieve the data on the page.

Let's take the `Shirt` resource class, and define a `:brand` attribute:

```ruby
module QA
  module Resource
    class Shirt < Base
      attr_accessor :name

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-to-create-a-shirt'
        end
      end

      # Attribute populated from the Browser UI (using the block)
      attribute :brand do
        Page::Shirt::Show.perform do |shirt_show|
          shirt_show.fetch_brand_from_page
        end
      end

      # ... same as before
    end
  end
end
```

**Note again that all the attributes are lazily constructed. This means if
you call `shirt.brand` after moving to the other page, it doesn't properly
retrieve the data because we're no longer on the expected page.**

Consider this:

```ruby
shirt =
  QA::Resource::Shirt.fabricate! do |resource|
    resource.name = "GitLab QA"
  end

shirt.project.visit!

shirt.brand # => FAIL!
```

The above example fails because now we're on the project page, trying to
construct the brand data from the shirt page, however we moved to the project
page already. There are two ways to solve this, one is that we could try to
retrieve the brand before visiting the project again:

```ruby
shirt =
  QA::Resource::Shirt.fabricate! do |resource|
    resource.name = "GitLab QA"
  end

shirt.brand # => OK!

shirt.project.visit!

shirt.brand # => OK!
```

The attribute is stored in the instance, therefore all the following calls
are fine, using the data previously constructed. If we think that this
might be too brittle, we could eagerly construct the data right before
ending fabrication:

```ruby
module QA
  module Resource
    class Shirt < Base
      # ... same as before

      def fabricate!
        project.visit!

        Page::Project::Show.perform do |project_show|
          project_show.go_to_new_shirt
        end

        Page::Shirt::New.perform do |shirt_new|
          shirt_new.set_name(name)
          shirt_new.create_shirt!
        end

        populate(:brand) # Eagerly construct the data
      end
    end
  end
end
```

The `populate` method iterates through its arguments and call each
attribute respectively. Here `populate(:brand)` has the same effect as
just `brand`. Using the populate method makes the intention clearer.

With this, it ensures we construct the data right after we create the
shirt. The drawback is that this always constructs the data when the
resource is fabricated even if we don't need to use the data.

Alternatively, we could just make sure we're on the right page before
constructing the brand data:

```ruby
module QA
  module Resource
    class Shirt < Base
      attr_accessor :name

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-to-create-a-shirt'
        end
      end

      # Attribute populated from the Browser UI (using the block)
      attribute :brand do
        back_url = current_url
        visit!

        Page::Shirt::Show.perform do |shirt_show|
          shirt_show.fetch_brand_from_page
        end

        visit(back_url)
      end

      # ... same as before
    end
  end
end
```

This ensures it's on the shirt page before constructing brand, and
move back to the previous page to avoid breaking the state.

#### Define an attribute based on an API response

Sometimes, you want to define a resource attribute based on the API response
from its `GET` or `POST` request. For instance, if the creation of a shirt via
the API returns

```ruby
{
  brand: 'a-brand-new-brand',
  style: 't-shirt',
  materials: [[:cotton, 80], [:polyamide, 20]]
}
```

you may want to store `style` as-is in the resource, and fetch the first value
of the first `materials` item in a `main_fabric` attribute.

Let's take the `Shirt` resource class, and define a `:style` and a
`:main_fabric` attributes:

```ruby
module QA
  module Resource
    class Shirt < Base
      # ... same as before

      # @style from the instance if present,
      # or fetched from the API response if present,
      # or a QA::Resource::Base::NoValueError is raised otherwise
      attribute :style

      # If @main_fabric is not present,
      # and if the API does not contain this field, this block will be
      # used to construct the value based on the API response, and
      # store the result in @main_fabric
      attribute :main_fabric do
        api_response.&dig(:materials, 0, 0)
      end

      # ... same as before
    end
  end
end
```

**Notes on attributes precedence:**

- resource instance variables have the highest precedence
- attributes from the API response take precedence over attributes from the
  block (usually from Browser UI)
- attributes without a value raises a `QA::Resource::Base::NoValueError` error

## Creating resources in your tests

To create a resource in your tests, you can call the `.fabricate!` method on
the resource class.
Note that if the resource class supports API fabrication, this uses this
fabrication by default.

Here is an example that uses the API fabrication method under the hood
since it's supported by the `Shirt` resource class:

```ruby
my_shirt = Resource::Shirt.fabricate! do |shirt|
  shirt.name = 'my-shirt'
end

expect(page).to have_text(my_shirt.name) # => "my-shirt" from the resource's instance variable
expect(page).to have_text(my_shirt.brand) # => "a-brand-new-brand" from the API response
expect(page).to have_text(my_shirt.style) # => "t-shirt" from the API response
expect(page).to have_text(my_shirt.main_fabric) # => "cotton" from the API response via the block
```

If you explicitly want to use the Browser UI fabrication method, you can call
the `.fabricate_via_browser_ui!` method instead:

```ruby
my_shirt = Resource::Shirt.fabricate_via_browser_ui! do |shirt|
  shirt.name = 'my-shirt'
end

expect(page).to have_text(my_shirt.name) # => "my-shirt" from the resource's instance variable
expect(page).to have_text(my_shirt.brand) # => the brand name fetched from the `Page::Shirt::Show` page via the block
expect(page).to have_text(my_shirt.style) # => QA::Resource::Base::NoValueError will be raised because no API response nor a block is provided
expect(page).to have_text(my_shirt.main_fabric) # => QA::Resource::Base::NoValueError will be raised because no API response and the block didn't provide a value (because it's also based on the API response)
```

You can also explicitly use the API fabrication method, by calling the
`.fabricate_via_api!` method:

```ruby
my_shirt = Resource::Shirt.fabricate_via_api! do |shirt|
  shirt.name = 'my-shirt'
end
```

In this case, the result is similar to calling `Resource::Shirt.fabricate!`.

## Reusable resources

Reusable resources are created by the first test that needs a particular kind of resource, and then any test that needs
the same kind of resource can reuse it instead of creating a new one.

The `ReusableProject` resource is an example of this class:

```ruby
module QA
  module Resource
    class ReusableProject < Project # A reusable resource inherits from the resource class that we want to be able to reuse.
      prepend Reusable # The Reusable module mixes in some methods that help implement reuse.

      def initialize
        super # A ReusableProject is a Project so it should be initialized as one.

        # Some Project attributes aren't valid and need to be overridden. For example, a ReusableProject keeps its name once it's created,
        # so we don't add a random string to the name specified.
        @add_name_uuid = false

        # It has a default name, and a different name can be specified when a resource is first created. However, the same name must be
        # provided any time that instance of the resource is used.
        @name = "reusable_project"

        # Several instances of a ReusableProject can exists as long as each is identified via a unique value for `reuse_as`.
        @reuse_as = :default_project
      end

      # All reusable resource classes must validate that an instance meets the conditions that allow reuse. For example,
      # by confirming that the name specified for the instance is valid and doesn't conflict with other instances.
      def validate_reuse_preconditions
        raise ResourceReuseError unless reused_name_valid?
      end
    end
  end
end
```

Consider some examples of how a reusable resource is used:

```ruby
# This will create a project.
default_project = Resource::ReusableProject.fabricate_via_api!
default_project.name # => "reusable_project"
default_project.reuse_as # => :default_project
```

Then in another test we could reuse the project:

```ruby
# This will fetch the project created above rather than creating a new one.
default_project_again = Resource::ReusableProject.fabricate_via_api!
default_project_again.name # => "reusable_project"
default_project_again.reuse_as # => :default_project
```

We can also create another project that we want to change in a way that might not be suitable for tests using the
default project:

```ruby
project_with_member = Resource::ReusableProject.fabricate_via_api! do |project|
  project.name = "project-with-member"
  project.reuse_as = :project_with_member
end

project_with_member.add_member(user)
```

Another test can reuse that project:

```ruby
project_still_has_member = Resource::ReusableProject.fabricate_via_api! do |project|
  project.name = "project-with-member"
  project.reuse_as = :project_with_member
end

expect(project_still_has_member).to have_member(user)
```

However, if we don't provide the name again an error will be raised:

```ruby
Resource::ReusableProject.fabricate_via_api! do |project|
  project.reuse_as = :project_with_member
end

# => ResourceReuseError will be raised because it will try to use the default name, "reusable_project", which doesn't
# match the name specified when the project was first fabricated.
```

## Where to ask for help?

If you need more information, ask for help on `#quality` channel on Slack
(internal, GitLab Team only).

If you are not a Team Member, and you still need help to contribute, please
open an issue in GitLab CE issue tracker with the `~QA` label.
