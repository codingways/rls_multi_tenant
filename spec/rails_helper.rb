# frozen_string_literal: true

require 'spec_helper'
require 'active_record'
require 'pg'
require 'logger'
require 'stringio'
require 'generator_spec'

# Minimal Rails shim. The gem only touches Rails.logger / Rails.version and
# subclasses Rails::Railtie; we avoid booting a full Rails app so the unit
# suite stays fast and the integration suite talks to a real database through
# plain ActiveRecord.
module Rails
  class Railtie
    def self.initializer(_name, **_options); end
  end

  Application = Class.new

  def self.logger
    @logger ||= Logger.new(StringIO.new)
  end

  def self.version
    ActiveRecord::VERSION::STRING
  end

  def self.env
    'test'
  end

  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.application
    @application ||= Application.new
  end
end

# Small Rack app stand-in used when instantiating the middleware in unit specs.
module Rack
  class App
    def call(_env)
      [200, {}, ['OK']]
    end
  end
end

# Load the gem under test.
require_relative '../lib/rls_multi_tenant'

# Load support files (shared helpers, DB harness, etc.).
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include GeneratorSpec::TestCase, type: :generator

  config.before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end
end
