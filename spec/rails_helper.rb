# frozen_string_literal: true

require 'spec_helper'
require 'generator_spec'

# Mock Rails for testing
module Rails
  def self.root
    Pathname.new(File.expand_path('../..', __FILE__))
  end

  def self.logger
    @logger ||= Logger.new(StringIO.new)
  end

  def self.env
    'test'
  end

  def self.application
    @application ||= double('application')
  end

  class Railtie
    def self.initializer(name, **options, &block)
      # Mock initializer registration
    end
  end
end

# Mock ActiveRecord
module ActiveRecord
  class Base
    def self.connection
      @connection ||= double('connection')
    end

    def self.connection_db_config
      @db_config ||= double('db_config', configuration_hash: { username: 'test_user' })
    end

    def self.execute(sql)
      connection.execute(sql)
    end
  end

  class Migration
    def self.[](version)
      self
    end
  end

  class StatementInvalid < StandardError; end
end

# Mock ActionDispatch
module ActionDispatch
  class Request
    def initialize(env)
      @env = env
    end

    def method
      @env['REQUEST_METHOD'] || 'GET'
    end

    def path
      @env['PATH_INFO'] || '/'
    end

    def host
      @env['HTTP_HOST'] || 'example.com'
    end
  end
end

# Mock PG
module PG
  class Error < StandardError; end
end

# Load the gem
require_relative '../lib/rls_multi_tenant'

RSpec.configure do |config|
  # Include generator spec helpers
  config.include GeneratorSpec::TestCase, type: :generator
  
  # Mock Rails components
  config.before(:each) do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end
end