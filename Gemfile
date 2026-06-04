# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Allow CI to pin a specific Rails version across the test matrix.
rails_version = ENV.fetch('RAILS_VERSION', nil)
gem 'rails', "~> #{rails_version}.0" if rails_version
