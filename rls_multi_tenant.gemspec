# frozen_string_literal: true

require_relative "lib/rls_multi_tenant/version"

Gem::Specification.new do |spec|
  spec.name = "rls_multi_tenant"
  spec.version = RlsMultiTenant::VERSION
  spec.authors = ["Coding Ways"]
  spec.email = ["info@codingways.com"]

  spec.summary = "Rails gem for PostgreSQL Row Level Security (RLS) multi-tenant applications"
  spec.description = "A comprehensive gem that provides RLS-based multi-tenancy for Rails applications using PostgreSQL, including automatic tenant context switching, security validations, and migration helpers."
  spec.homepage = "https://github.com/codingways/rls_multi_tenant"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/codingways/rls_multi_tenant"
  spec.metadata["changelog_uri"] = "https://github.com/codingways/rls_multi_tenant/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "pg", ">= 1.0"

  # Development dependencies
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rails", "~> 2.20"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "generator_spec", "~> 0.9"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
end
