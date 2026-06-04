# frozen_string_literal: true

# Snapshot and restore the gem's global configuration around every example, so
# a spec that mutates RlsMultiTenant config can never leak into another example
# (which matters now that specs run in random order).
module ConfigurationIsolation
  ATTRS = %i[
    tenant_class_name
    tenant_id_column
    enable_security_validation
    enable_subdomain_middleware
    subdomain_field
    excluded_subdomains
  ].freeze

  module_function

  def snapshot
    ATTRS.index_with { |attr| RlsMultiTenant.public_send(attr) }
  end

  def restore(snapshot)
    snapshot.each { |attr, value| RlsMultiTenant.public_send("#{attr}=", value) }
  end
end

RSpec.configure do |config|
  config.around do |example|
    saved = ConfigurationIsolation.snapshot
    example.run
    ConfigurationIsolation.restore(saved)
  end
end
