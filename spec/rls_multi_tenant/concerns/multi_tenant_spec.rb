# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RlsMultiTenant::Concerns::MultiTenant do
  describe 'module structure' do
    it 'is a module' do
      expect(described_class).to be_a(Module)
    end

    it 'extends ActiveSupport::Concern' do
      expect(described_class.ancestors).to include(ActiveSupport::Concern)
    end
  end

  describe 'module functionality' do
    # Test that the module can be included in a class
    it 'can be included in a class' do
      # Mock ActiveRecord::Base for the test
      mock_active_record = Class.new do
        def self.belongs_to(*args); end
        def self.validates(*args); end
        def self.before_validation(*args); end
      end
      
      test_class = Class.new(mock_active_record) do
        include RlsMultiTenant::Concerns::MultiTenant
      end
      
      expect(test_class.ancestors).to include(RlsMultiTenant::Concerns::MultiTenant)
    end
  end
end
