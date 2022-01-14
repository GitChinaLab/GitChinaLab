# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:ldap:rename_provider rake task', :silence_stdout do
  it 'completes without error' do
    Rake.application.rake_require 'tasks/gitlab/ldap'
    stub_warn_user_is_not_gitlab
    stub_env('force', 'yes')

    create(:identity) # Necessary to prevent `exit 1` from the task.

    run_rake_task('gitlab:ldap:rename_provider', 'ldapmain', 'ldapfoo')
  end
end

RSpec.describe 'gitlab:ldap:secret rake tasks' do
  let(:ldap_secret_file) { 'tmp/tests/ldapenc/ldap_secret.yaml.enc' }

  before do
    Rake.application.rake_require 'tasks/gitlab/ldap'
    stub_env('EDITOR', 'cat')
    stub_warn_user_is_not_gitlab
    FileUtils.mkdir_p('tmp/tests/ldapenc/')
    allow(Gitlab.config.ldap).to receive(:secret_file).and_return(ldap_secret_file)
    allow(Gitlab::Application.secrets).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
  end

  after do
    FileUtils.rm_rf(Rails.root.join('tmp/tests/ldapenc'))
  end

  describe ':show' do
    it 'displays error when file does not exist' do
      expect { run_rake_task('gitlab:ldap:secret:show') }.to output(/File .* does not exist. Use `gitlab-rake gitlab:ldap:secret:edit` to change that./).to_stdout
    end

    it 'displays error when key does not exist' do
      Settings.encrypted(ldap_secret_file).write('somevalue')
      allow(Gitlab::Application.secrets).to receive(:encrypted_settings_key_base).and_return(nil)
      expect { run_rake_task('gitlab:ldap:secret:show') }.to output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when key is changed' do
      Settings.encrypted(ldap_secret_file).write('somevalue')
      allow(Gitlab::Application.secrets).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
      expect { run_rake_task('gitlab:ldap:secret:show') }.to output(/Couldn't decrypt .* Perhaps you passed the wrong key?/).to_stderr
    end

    it 'outputs the unencrypted content when present' do
      encrypted = Settings.encrypted(ldap_secret_file)
      encrypted.write('somevalue')
      expect { run_rake_task('gitlab:ldap:secret:show') }.to output(/somevalue/).to_stdout
    end
  end

  describe 'edit' do
    it 'creates encrypted file' do
      expect { run_rake_task('gitlab:ldap:secret:edit') }.to output(/File encrypted and saved./).to_stdout
      expect(File.exist?(ldap_secret_file)).to be true
      value = Settings.encrypted(ldap_secret_file)
      expect(value.read).to match(/password: '123'/)
    end

    it 'displays error when key does not exist' do
      allow(Gitlab::Application.secrets).to receive(:encrypted_settings_key_base).and_return(nil)
      expect { run_rake_task('gitlab:ldap:secret:edit') }.to output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when key is changed' do
      Settings.encrypted(ldap_secret_file).write('somevalue')
      allow(Gitlab::Application.secrets).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
      expect { run_rake_task('gitlab:ldap:secret:edit') }.to output(/Couldn't decrypt .* Perhaps you passed the wrong key?/).to_stderr
    end

    it 'displays error when write directory does not exist' do
      FileUtils.rm_rf(Rails.root.join('tmp/tests/ldapenc'))
      expect { run_rake_task('gitlab:ldap:secret:edit') }.to output(/Directory .* does not exist./).to_stderr
    end

    it 'shows a warning when content is invalid' do
      Settings.encrypted(ldap_secret_file).write('somevalue')
      expect { run_rake_task('gitlab:ldap:secret:edit') }.to output(/WARNING: Content was not a valid LDAP secret yml file/).to_stdout
      value = Settings.encrypted(ldap_secret_file)
      expect(value.read).to match(/somevalue/)
    end

    it 'displays error when $EDITOR is not set' do
      stub_env('EDITOR', nil)
      expect { run_rake_task('gitlab:ldap:secret:edit') }.to output(/No \$EDITOR specified to open file. Please provide one when running the command/).to_stderr
    end
  end

  describe 'write' do
    before do
      allow($stdin).to receive(:tty?).and_return(false)
      allow($stdin).to receive(:read).and_return('testvalue')
    end

    it 'creates encrypted file from stdin' do
      expect { run_rake_task('gitlab:ldap:secret:write') }.to output(/File encrypted and saved./).to_stdout
      expect(File.exist?(ldap_secret_file)).to be true
      value = Settings.encrypted(ldap_secret_file)
      expect(value.read).to match(/testvalue/)
    end

    it 'displays error when key does not exist' do
      allow(Gitlab::Application.secrets).to receive(:encrypted_settings_key_base).and_return(nil)
      expect { run_rake_task('gitlab:ldap:secret:write') }.to output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when write directory does not exist' do
      FileUtils.rm_rf('tmp/tests/ldapenc/')
      expect { run_rake_task('gitlab:ldap:secret:write') }.to output(/Directory .* does not exist./).to_stderr
    end

    it 'shows a warning when content is invalid' do
      Settings.encrypted(ldap_secret_file).write('somevalue')
      expect { run_rake_task('gitlab:ldap:secret:edit') }.to output(/WARNING: Content was not a valid LDAP secret yml file/).to_stdout
      value = Settings.encrypted(ldap_secret_file)
      expect(value.read).to match(/somevalue/)
    end
  end
end
