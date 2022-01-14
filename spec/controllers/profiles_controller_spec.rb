# frozen_string_literal: true

require('spec_helper')

RSpec.describe ProfilesController, :request_store do
  let(:password) { 'longsecret987!' }
  let(:user) { create(:user, password: password) }

  describe 'POST update' do
    it 'does not update password' do
      sign_in(user)

      expect do
        post :update,
             params: { user: { password: 'hello12345', password_confirmation: 'hello12345' } }
      end.not_to change { user.reload.encrypted_password }

      expect(response).to have_gitlab_http_status(:found)
    end
  end

  describe 'PUT update' do
    it 'allows an email update from a user without an external email address' do
      sign_in(user)

      put :update,
          params: { user: { email: "john@gmail.com", name: "John", validation_password: password } }

      user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(user.unconfirmed_email).to eq('john@gmail.com')
    end

    it "allows an email update without confirmation if existing verified email" do
      user = create(:user)
      create(:email, :confirmed, user: user, email: 'john@gmail.com')
      sign_in(user)

      put :update,
          params: { user: { email: "john@gmail.com", name: "John" } }

      user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(user.unconfirmed_email).to eq nil
    end

    it 'ignores an email update from a user with an external email address' do
      stub_omniauth_setting(sync_profile_from_provider: ['ldap'])
      stub_omniauth_setting(sync_profile_attributes: true)

      ldap_user = create(:omniauth_user)
      ldap_user.create_user_synced_attributes_metadata(provider: 'ldap', name_synced: true, email_synced: true)
      sign_in(ldap_user)

      put :update,
          params: { user: { email: "john@gmail.com", name: "John" } }

      ldap_user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(ldap_user.unconfirmed_email).not_to eq('john@gmail.com')
    end

    it 'ignores an email and name update but allows a location update from a user with external email and name, but not external location' do
      stub_omniauth_setting(sync_profile_from_provider: ['ldap'])
      stub_omniauth_setting(sync_profile_attributes: true)

      ldap_user = create(:omniauth_user, name: 'Alex')
      ldap_user.create_user_synced_attributes_metadata(provider: 'ldap', name_synced: true, email_synced: true, location_synced: false)
      sign_in(ldap_user)

      put :update,
          params: { user: { email: "john@gmail.com", name: "John", location: "City, Country" } }

      ldap_user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(ldap_user.unconfirmed_email).not_to eq('john@gmail.com')
      expect(ldap_user.name).not_to eq('John')
      expect(ldap_user.location).to eq('City, Country')
    end

    it 'allows setting a user status' do
      sign_in(user)

      put :update, params: { user: { status: { message: 'Working hard!', availability: 'busy' } } }

      expect(user.reload.status.message).to eq('Working hard!')
      expect(user.reload.status.availability).to eq('busy')
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows updating user specified job title' do
      title = 'Marketing Executive'
      sign_in(user)

      put :update, params: { user: { job_title: title } }

      expect(user.reload.job_title).to eq(title)
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows updating user specified pronouns', :aggregate_failures do
      pronouns = 'they/them'
      sign_in(user)

      put :update, params: { user: { pronouns: pronouns } }

      expect(user.reload.pronouns).to eq(pronouns)
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows updating user specified pronunciation', :aggregate_failures do
      user = create(:user, name: 'Example')
      pronunciation = 'uhg-zaam-pl'
      sign_in(user)

      put :update, params: { user: { pronunciation: pronunciation } }

      expect(user.reload.pronunciation).to eq(pronunciation)
      expect(response).to have_gitlab_http_status(:found)
    end
  end

  describe 'GET audit_log' do
    let(:auth_event) { create(:authentication_event, user: user) }

    it 'tracks search event', :snowplow do
      sign_in(user)

      get :audit_log

      expect_snowplow_event(
        category: 'ProfilesController',
        action: 'search_audit_event',
        user: user
      )
    end

    it 'loads page correctly' do
      sign_in(user)

      get :audit_log

      expect(response).to have_gitlab_http_status(:success)
    end
  end

  describe 'PUT update_username' do
    let(:namespace) { user.namespace }
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:new_username) { generate(:username) }

    it 'allows username change' do
      sign_in(user)

      put :update_username,
        params: { user: { username: new_username } }

      user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(user.username).to eq(new_username)
    end

    it 'updates a username using JSON request' do
      sign_in(user)

      put :update_username,
          params: {
            user: { username: new_username }
          },
          format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['message']).to eq(s_('Profiles|Username successfully changed'))
    end

    it 'renders an error message when the username was not updated' do
      sign_in(user)

      put :update_username,
          params: {
            user: { username: 'invalid username.git' }
          },
          format: :json

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(json_response['message']).to match(/Username change failed/)
    end

    it 'raises a correct error when the username is missing' do
      sign_in(user)

      expect { put :update_username, params: { user: { gandalf: 'you shall not pass' } } }
        .to raise_error(ActionController::ParameterMissing)
    end

    context 'with legacy storage' do
      it 'moves dependent projects to new namespace' do
        project = create(:project_empty_repo, :legacy_storage, namespace: namespace)

        sign_in(user)

        put :update_username,
          params: { user: { username: new_username } }

        user.reload

        expect(response).to have_gitlab_http_status(:found)
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_username}/#{project.path}.git")).to be_truthy
      end
    end

    context 'with hashed storage' do
      it 'keeps repository location unchanged on disk' do
        project = create(:project_empty_repo, namespace: namespace)

        before_disk_path = project.disk_path

        sign_in(user)

        put :update_username,
          params: { user: { username: new_username } }

        user.reload

        expect(response).to have_gitlab_http_status(:found)
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{project.disk_path}.git")).to be_truthy
        expect(before_disk_path).to eq(project.disk_path)
      end
    end
  end
end
