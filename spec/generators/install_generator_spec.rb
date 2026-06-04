# frozen_string_literal: true

require 'rails_helper'
require 'rls_multi_tenant/generators/install/install_generator'

RSpec.describe RlsMultiTenant::Generators::InstallGenerator, type: :generator do
  destination File.expand_path('../tmp/generators', __dir__)

  before do
    prepare_destination
    run_generator
  end

  it 'creates the initializer with the configuration block' do
    assert_file 'config/initializers/rls_multi_tenant.rb',
                /RlsMultiTenant\.configure do \|config\|/,
                /config\.tenant_class_name = 'Tenant'/,
                /config\.enable_security_validation = true/
  end
end
