# frozen_string_literal: true
FactoryBot.define do
  factory :package, class: 'Packages::Package' do
    project
    creator { project&.creator }
    name { 'my/company/app/my-app' }
    sequence(:version) { |n| "1.#{n}-SNAPSHOT" }
    package_type { :maven }
    status { :default }

    trait :hidden do
      status { :hidden }
    end

    trait :processing do
      status { :processing }
    end

    trait :error do
      status { :error }
    end

    factory :maven_package do
      maven_metadatum

      after :build do |package|
        package.maven_metadatum.path = package.version? ? "#{package.name}/#{package.version}" : package.name
      end

      after :create do |package|
        create :package_file, :xml, package: package
        create :package_file, :jar, package: package
        create :package_file, :pom, package: package
      end
    end

    factory :rubygems_package do
      sequence(:name) { |n| "my_gem_#{n}" }
      sequence(:version) { |n| "1.#{n}" }
      package_type { :rubygems }

      after :create do |package|
        create :package_file, package.processing? ? :unprocessed_gem : :gem, package: package
        create :package_file, :gemspec, package: package unless package.processing?
      end

      trait(:with_metadatum) do
        after :build do |pkg|
          pkg.rubygems_metadatum = build(:rubygems_metadatum)
        end
      end
    end

    factory :debian_package do
      sequence(:name) { |n| "package-#{n}" }
      sequence(:version) { |n| "1.0-#{n}" }
      package_type { :debian }

      transient do
        without_package_files { false }
        file_metadatum_trait { :keep }
        published_in { :create }
      end

      after :build do |package, evaluator|
        if evaluator.published_in == :create
          create(:debian_publication, package: package)
        elsif !evaluator.published_in.nil?
          create(:debian_publication, package: package, distribution: evaluator.published_in)
        end
      end

      after :create do |package, evaluator|
        unless evaluator.without_package_files
          create :debian_package_file, :source, evaluator.file_metadatum_trait, package: package
          create :debian_package_file, :dsc, evaluator.file_metadatum_trait, package: package
          create :debian_package_file, :deb, evaluator.file_metadatum_trait, package: package
          create :debian_package_file, :deb_dev, evaluator.file_metadatum_trait, package: package
          create :debian_package_file, :udeb, evaluator.file_metadatum_trait, package: package
          create :debian_package_file, :buildinfo, evaluator.file_metadatum_trait, package: package
          create :debian_package_file, :changes, evaluator.file_metadatum_trait, package: package
        end
      end

      factory :debian_incoming do
        name { 'incoming' }
        version { nil }

        transient do
          without_package_files { false }
          file_metadatum_trait { :unknown }
          published_in { nil }
        end
      end
    end

    factory :helm_package do
      sequence(:name) { |n| "package-#{n}" }
      sequence(:version) { |n| "v1.0.#{n}" }
      package_type { :helm }

      transient do
        without_package_files { false }
      end

      after :create do |package, evaluator|
        unless evaluator.without_package_files
          create :helm_package_file, package: package
        end
      end
    end

    factory :npm_package do
      sequence(:name) { |n| "@#{project.root_namespace.path}/package-#{n}"}
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :npm }

      after :create do |package|
        create :package_file, :npm, package: package
      end

      trait :with_build do
        after :create do |package|
          user = package.project.creator
          pipeline = create(:ci_pipeline, user: user)
          create(:ci_build, user: user, pipeline: pipeline)
          create :package_build_info, package: package, pipeline: pipeline
        end
      end
    end

    factory :terraform_module_package do
      sequence(:name) { |n| "module-#{n}/system" }
      version { '1.0.0' }
      package_type { :terraform_module }

      after :create do |package|
        create :package_file, :terraform_module, package: package
      end

      trait :with_build do
        after :create do |package|
          user = package.project.creator
          pipeline = create(:ci_pipeline, user: user)
          create(:ci_build, user: user, pipeline: pipeline)
          create :package_build_info, package: package, pipeline: pipeline
        end
      end
    end

    factory :nuget_package do
      sequence(:name) { |n| "NugetPackage#{n}"}
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :nuget }

      after :create do |package|
        create :package_file, :nuget, package: package, file_name: "#{package.name}.#{package.version}.nupkg"
      end

      trait(:with_metadatum) do
        after :build do |pkg|
          pkg.nuget_metadatum = build(:nuget_metadatum)
        end
      end

      trait(:with_symbol_package) do
        after :create do |package|
          create :package_file, :snupkg, package: package, file_name: "#{package.name}.#{package.version}.snupkg"
        end
      end
    end

    factory :pypi_package do
      sequence(:name) { |n| "pypi-package-#{n}"}
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :pypi }

      transient do
        without_loaded_metadatum { false }
      end

      after :create do |package, evaluator|
        create :package_file, :pypi, package: package, file_name: "#{package.name}-#{package.version}.tar.gz"

        unless evaluator.without_loaded_metadatum
          create :pypi_metadatum, package: package
        end
      end
    end

    factory :composer_package do
      sequence(:name) { |n| "composer-package-#{n}"}
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :composer }

      transient do
        sha { project.repository.find_branch('master').target }
        json { { name: name, version: version } }
      end

      trait(:with_metadatum) do
        after :create do |package, evaluator|
          create :composer_metadatum, package: package, target_sha: evaluator.sha, composer_json: evaluator.json
        end
      end
    end

    factory :golang_package do
      sequence(:name) { |n| "golang.org/x/pkg-#{n}"}
      sequence(:version) { |n| "v1.0.#{n}" }
      package_type { :golang }
    end

    factory :conan_package do
      conan_metadatum

      transient do
        without_package_files { false }
      end

      after :build do |package|
        package.conan_metadatum.package_username = Packages::Conan::Metadatum.package_username_from(
          full_path: package.project.full_path
        )
      end

      sequence(:name) { |n| "package-#{n}" }
      version { '1.0.0' }
      package_type { :conan }

      after :create do |package, evaluator|
        unless evaluator.without_package_files
          create :conan_package_file, :conan_recipe_file, package: package
          create :conan_package_file, :conan_recipe_manifest, package: package
          create :conan_package_file, :conan_package_info, package: package
          create :conan_package_file, :conan_package_manifest, package: package
          create :conan_package_file, :conan_package, package: package
        end
      end

      trait(:without_loaded_metadatum) do
        conan_metadatum { build(:conan_metadatum, package: nil) } # rubocop:disable FactoryBot/InlineAssociation
      end
    end

    factory :generic_package do
      sequence(:name) { |n| "generic-package-#{n}" }
      version { '1.0.0' }
      package_type { :generic }

      trait(:with_zip_file) do
        after :create do |package|
          create :package_file, :generic_zip, package: package
        end
      end
    end
  end
end
