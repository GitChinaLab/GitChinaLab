# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateRemainingU2fRegistrations, :migration do
  let(:u2f_registrations) { table(:u2f_registrations) }
  let(:webauthn_registrations) { table(:webauthn_registrations) }
  let(:users) { table(:users) }

  let(:user) { users.create!(email: 'email@email.com', name: 'foo', username: 'foo', projects_limit: 0) }

  before do
    create_u2f_registration(1, 'reg1')
    create_u2f_registration(2, 'reg2')
    create_u2f_registration(3, '')
    create_u2f_registration(4, nil)
    webauthn_registrations.create!({ name: 'reg1', u2f_registration_id: 1, credential_xid: '', public_key: '', user_id: user.id })
  end

  it 'correctly migrates u2f registrations previously not migrated' do
    expect { migrate! }.to change { webauthn_registrations.count }.from(1).to(4)
  end

  it 'migrates all valid u2f registrations depite errors' do
    create_u2f_registration(5, 'reg3', 'invalid!')
    create_u2f_registration(6, 'reg4')

    expect { migrate! }.to change { webauthn_registrations.count }.from(1).to(5)
  end

  def create_u2f_registration(id, name, public_key = nil)
    device = U2F::FakeU2F.new(FFaker::BaconIpsum.characters(5), { key_handle: SecureRandom.random_bytes(255) })
    public_key ||= Base64.strict_encode64(device.origin_public_key_raw)
    u2f_registrations.create!({ id: id,
                               certificate: Base64.strict_encode64(device.cert_raw),
                               key_handle: U2F.urlsafe_encode64(device.key_handle_raw),
                               public_key: public_key,
                               counter: 5,
                               name: name,
                               user_id: user.id })
  end
end
