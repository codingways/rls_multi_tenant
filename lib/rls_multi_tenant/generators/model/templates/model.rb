# frozen_string_literal: true

class <%= model_name %> < ApplicationRecord
  include RlsMultiTenant::Concerns::MultiTenant
end
