# frozen_string_literal: true

FactoryBot.define do
  factory :packages_dependency_link, class: 'Packages::DependencyLink' do
    package { association(:nuget_package) }
    dependency { association(:packages_dependency) }
    dependency_type { :dependencies }

    trait(:with_nuget_metadatum) do
      after :build do |link|
        link.nuget_metadatum = build(:nuget_dependency_link_metadatum)
      end
    end

    trait(:rubygems) do
      package { association(:rubygems_package) }
      dependency { association(:packages_dependency, :rubygems) }
    end
  end
end
