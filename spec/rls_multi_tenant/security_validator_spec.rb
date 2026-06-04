# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RlsMultiTenant::SecurityValidator do
  subject(:validate) { described_class.validate_database_user! }

  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }

  before { allow(ActiveRecord::Base).to receive(:connection).and_return(connection) }

  def stub_role(username: 'app', superuser: false, bypassrls: false)
    allow(connection).to receive(:execute).and_return(
      [{ 'username' => username, 'rolsuper' => superuser, 'rolbypassrls' => bypassrls }]
    )
  end

  context 'with a non-privileged role' do
    before { stub_role }

    it 'does not raise' do
      expect { validate }.not_to raise_error
    end
  end

  context 'with a superuser' do
    before { stub_role(superuser: true) }

    it 'raises a SecurityError mentioning SUPERUSER' do
      expect { validate }.to raise_error(RlsMultiTenant::SecurityError, /SUPERUSER/)
    end
  end

  context 'with a BYPASSRLS role' do
    before { stub_role(bypassrls: true) }

    it 'raises a SecurityError mentioning BYPASSRLS' do
      expect { validate }.to raise_error(RlsMultiTenant::SecurityError, /BYPASSRLS/)
    end
  end

  context 'when the adapter returns string booleans' do
    before { stub_role(superuser: 't') }

    it 'treats "t" as true' do
      expect { validate }.to raise_error(RlsMultiTenant::SecurityError, /SUPERUSER/)
    end
  end

  context 'when security validation is disabled' do
    before { allow(RlsMultiTenant).to receive(:enable_security_validation).and_return(false) }

    it 'does not query the database' do
      expect(connection).not_to receive(:execute) # rubocop:disable RSpec/MessageSpies
      validate
    end
  end
end
