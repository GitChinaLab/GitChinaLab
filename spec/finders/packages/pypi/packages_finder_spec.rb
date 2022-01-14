# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Pypi::PackagesFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:package1) { create(:pypi_package, project: project) }
  let_it_be(:package2) { create(:pypi_package, project: project) }
  let_it_be(:package3) { create(:pypi_package, name: package2.name, project: project) }
  let_it_be(:package4) { create(:pypi_package, name: package2.name, project: project2) }

  let(:package_name) { package2.name }

  describe 'execute' do
    subject { described_class.new(user, scope, package_name: package_name).execute }

    shared_examples 'when no package is found' do
      context 'non-existing package' do
        let(:package_name) { 'none' }

        it { expect(subject).to be_empty }
      end
    end

    shared_examples 'when package_name param is a non-normalized name' do
      context 'non-existing package' do
        let(:package_name) { package2.name.upcase.tr('-', '.') }

        it { expect(subject).to be_empty }
      end
    end

    context 'within a project' do
      let(:scope) { project }

      it { is_expected.to contain_exactly(package2, package3) }

      it_behaves_like 'when no package is found'
      it_behaves_like 'when package_name param is a non-normalized name'
    end

    context 'within a group' do
      let(:scope) { group }

      it { expect(subject).to be_empty }

      context 'user with access to only one project' do
        before do
          project2.add_developer(user)
        end

        it { is_expected.to contain_exactly(package4) }

        it_behaves_like 'when no package is found'
        it_behaves_like 'when package_name param is a non-normalized name'

        context ' user with access to multiple projects' do
          before do
            project.add_developer(user)
          end

          it { is_expected.to contain_exactly(package2, package3, package4) }
        end
      end
    end
  end
end
