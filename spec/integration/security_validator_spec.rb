# frozen_string_literal: true

require 'rails_helper'

# Runs the security validator against real PostgreSQL roles with different
# privilege levels (see spec/support/db.rb).
RSpec.describe RlsMultiTenant::SecurityValidator, :integration do
  # Restore the default unprivileged connection for subsequent examples, since
  # these examples reconnect as other roles.
  after { IntegrationDB.connect_as!(IntegrationDB::APP_ROLE) }

  it 'passes for a non-privileged role' do
    IntegrationDB.connect_as!(IntegrationDB::APP_ROLE)

    expect { described_class.validate_database_user! }.not_to raise_error
  end

  it 'rejects a SUPERUSER' do
    IntegrationDB.connect_admin!

    expect { described_class.validate_database_user! }
      .to raise_error(RlsMultiTenant::SecurityError, /SUPERUSER/)
  end

  it 'rejects a role with BYPASSRLS' do
    IntegrationDB.connect_as!(IntegrationDB::BYPASS_ROLE)

    expect { described_class.validate_database_user! }
      .to raise_error(RlsMultiTenant::SecurityError, /BYPASSRLS/)
  end

  # A role that merely belongs to a BYPASSRLS group does NOT bypass RLS:
  # PostgreSQL does not inherit role attributes through membership. The
  # validator must therefore accept it.
  it 'passes for a role that only inherits BYPASSRLS through membership' do
    IntegrationDB.connect_as!(IntegrationDB::MEMBER_ROLE)

    expect { described_class.validate_database_user! }.not_to raise_error
  end
end
