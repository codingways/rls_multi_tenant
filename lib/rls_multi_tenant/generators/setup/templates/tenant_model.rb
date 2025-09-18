# frozen_string_literal: true

class <%= RlsMultiTenant.tenant_class_name %> < ApplicationRecord
  include RlsMultiTenant::Concerns::TenantContext

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true
end
