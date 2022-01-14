# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::DebianGroupPackages do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :group, false do
    context 'with invalid parameter' do
      let(:url) { "/groups/1/-/packages/debian/dists/with+space/InRelease" }

      it_behaves_like 'Debian packages GET request', :bad_request, /^distribution is invalid$/
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/Release.gpg' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution.codename}/Release.gpg" }

      it_behaves_like 'Debian packages read endpoint', 'GET', :success, /^-----BEGIN PGP SIGNATURE-----/
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/Release' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution.codename}/Release" }

      it_behaves_like 'Debian packages read endpoint', 'GET', :success, /^Codename: fixture-distribution\n$/
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/InRelease' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution.codename}/InRelease" }

      it_behaves_like 'Debian packages read endpoint', 'GET', :success, /^-----BEGIN PGP SIGNED MESSAGE-----/
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/:component/binary-:architecture/Packages' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution.codename}/#{component.name}/binary-#{architecture.name}/Packages" }

      it_behaves_like 'Debian packages read endpoint', 'GET', :success, /Description: This is an incomplete Packages file/
    end

    describe 'GET groups/:id/-/packages/debian/pool/:codename/:project_id/:letter/:package_name/:package_version/:file_name' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/pool/#{package.debian_distribution.codename}/#{project.id}/#{letter}/#{package.name}/#{package.version}/#{file_name}" }
      let(:file_name) { params[:file_name] }

      using RSpec::Parameterized::TableSyntax

      where(:file_name, :success_body) do
        'sample_1.2.3~alpha2.tar.xz'          | /^.7zXZ/
        'sample_1.2.3~alpha2.dsc'             | /^Format: 3.0 \(native\)/
        'libsample0_1.2.3~alpha2_amd64.deb'   | /^!<arch>/
        'sample-udeb_1.2.3~alpha2_amd64.udeb' | /^!<arch>/
        'sample_1.2.3~alpha2_amd64.buildinfo' | /Build-Tainted-By/
        'sample_1.2.3~alpha2_amd64.changes'   | /urgency=medium/
      end

      with_them do
        it_behaves_like 'Debian packages read endpoint', 'GET', :success, params[:success_body]
      end
    end
  end
end
