# frozen_string_literal: true

class Tenant < ApplicationRecord
  include RlsMultiTenant::Concerns::TenantContext

  validates :name, presence: true
end
