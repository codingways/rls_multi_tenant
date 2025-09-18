# RLS Multi-Tenant

[![CI](https://github.com/codingways/rls_multi_tenant/actions/workflows/simple.yml/badge.svg)](https://github.com/codingways/rls_multi_tenant/actions/workflows/simple.yml)
[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/rails-6.0%2B-red.svg)](https://rubyonrails.org/)
[![Gem Version](https://badge.fury.io/rb/rls_multi_tenant.svg)](https://badge.fury.io/rb/rls_multi_tenant)
[![Downloads](https://img.shields.io/gem/dt/rls_multi_tenant.svg)](https://rubygems.org/gems/rls_multi_tenant)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Rails gem that provides PostgreSQL Row Level Security (RLS) based multi-tenancy for Rails applications.

> 📚 **Learn more about PostgreSQL Row Level Security**: [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)

## ⚠️ IMPORTANT: Database Security Setup for RLS

**This gem relies on PostgreSQL Row-Level Security (RLS) for tenant isolation. You MUST create a dedicated database role with proper RLS permissions before using this gem in production.**

## Features

- 🔒 **Row Level Security**: Automatic tenant isolation using PostgreSQL RLS
- 🛡️ **Security Validation**: Prevents running with privileged database users
- 🔄 **Context Switching**: Easy tenant context management
- 📦 **Auto-inclusion**: Automatic model configuration
- 🚀 **Generators**: Rails generators for quick setup
- ⚙️ **Configurable**: Flexible configuration options
- 🌐 **Subdomain Middleware**: Automatic tenant switching based on subdomain

### Create Application Database Role

Create a dedicated role for your Rails application:

```sql
CREATE ROLE app_user
  WITH LOGIN
       CREATEDB          -- can create databases
       CREATEROLE        -- can create/modify other roles (except superuser)
       NOINHERIT         -- does not inherit privileges from roles it belongs to
       NOREPLICATION     -- cannot use replication
       NOBYPASSRLS       -- cannot bypass Row-Level Security
       NOSUPERUSER       -- is not a superuser
       PASSWORD 'strong_password';
```

If you don't have a database created, you can create one with the new role:

```sql
CREATE DATABASE your_db_name OWNER app_user;
```

If you already have a database created, make sure to grant ownership of the database to the new role:

```sql
ALTER DATABASE your_db_name OWNER TO app_user;
```

### Why This Role Configuration is Critical for RLS

- **`NOBYPASSRLS`**: **ESSENTIAL for RLS security** - prevents bypassing Row-Level Security policies that enforce tenant isolation
- **`NOSUPERUSER`**: Prevents superuser privileges that could compromise RLS policies
- **`LOGIN`**: Allows the role to connect to the database
- **`CREATEDB`**: Enables database creation for development/testing environments
- **`CREATEROLE`**: Allows creating other roles for application-specific users
- **`NOINHERIT`**: Ensures the role does not inherit privileges from parent roles
- **`NOREPLICATION`**: Prevents the role from being used for replication (security)

**Without `NOBYPASSRLS`, Row-Level Security policies can be bypassed, completely breaking tenant isolation and exposing data across tenants.**

### Update Database Configuration

Update your `config/database.yml` to use the new role:

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rls_multi_tenant'
```

And then execute:

```bash
bundle install
```

## Quick Start

1. **Install the gem configuration:**
   ```bash
   rails generate rls_multi_tenant:install
   ```

2. **Configure the gem settings:**
   Edit `config/initializers/rls_multi_tenant.rb` to customize your tenant model:
    ```ruby
    RlsMultiTenant.configure do |config|
      config.tenant_class_name = "Tenant"           # Your tenant model class (e.g., "Organization", "Company")
      config.tenant_id_column = :tenant_id          # Tenant ID column name
      config.enable_security_validation = true      # Enable security checks (prevents running with superuser privileges)
      config.enable_subdomain_middleware = true     # Enable subdomain-based tenant switching (default: true)
      config.subdomain_field = :subdomain           # Field to use for subdomain matching (default: :subdomain)
    end
    ```
3. **Setup the tenant model and migrations:**
   ```bash
   rails generate rls_multi_tenant:setup
   ```

4. **Run migrations:**
   ```bash
   rails db:migrate
   ```

## Usage

### Basic Multi-Tenant Models

Create a new model:
```bash
rails generate rls_multi_tenant:model User name email
```

Your models automatically include the `MultiTenant` concern:

```ruby
class User < ApplicationRecord
  # Automatically includes MultiTenant concern
  include RlsMultiTenant::Concerns::MultiTenant
end
```

### Tenant Context Switching

```ruby
# Create a new tenant with subdomain
tenant = Tenant.create!(name: "Company A", subdomain: "company-a")
```

```ruby
# Switch tenant context for a block
Tenant.switch(tenant) do
  User.create!(name: "User from Company A", email: "user@company-a.com") # Automatically assigned to current tenant
end

# Switch tenant context permanently
Tenant.switch!(tenant)
User.create!(name: "User from Company A", email: "user@company-a.com")
Tenant.reset! # Reset context

# Get current tenant
current_tenant = Tenant.current
```

### Automatic Subdomain-Based Tenant Switching

The gem includes middleware that automatically switches tenants based on the request subdomain. This is enabled by default and works seamlessly with your tenant model.

**The middleware automatically:**
- Extracts the subdomain from the request host
- Finds the matching tenant by the subdomain field
- Switches the tenant context for the duration of the request
- Resets the context after the request completes

**Usage:**
```ruby
# Create tenants with subdomains
tenant1 = Tenant.create!(name: "Company A", subdomain: "company-a")
tenant2 = Tenant.create!(name: "Company B", subdomain: "company-b")

# Users visiting company-a.yourdomain.com will automatically be in tenant1's context
# Users visiting company-b.yourdomain.com will automatically be in tenant2's context
# Users visiting yourdomain.com (no subdomain) will have no tenant context
```

### Public Access (Non-Tenanted Models)

Models that don't include `RlsMultiTenant::Concerns::TenantContext` are automatically treated as public models and can be accessed without tenant context. This provides a secure, explicit way to separate tenant-specific and public models.

**Example:**
```ruby
# Public models (no tenant association)
class PublicPost < ApplicationRecord
  # No TenantContext concern included
  # These models are accessible without tenant context
end

# Tenant-specific models (automatically generated)
class User < ApplicationRecord
  # Automatically includes MultiTenant concern
  # These models require tenant context and are constrained by RLS
  include RlsMultiTenant::Concerns::MultiTenant
end
```

**Security Benefits:**
- **Explicit Intent**: Models must explicitly include `TenantContext` to be tenant-constrained
- **Fail-Safe**: Public models are clearly separated from tenant models
- **No Configuration Drift**: Can't accidentally expose tenant data through misconfiguration

## Requirements

- Rails 6.0+
- PostgreSQL 9.5+ (with UUID extension support)
- Ruby 2.7+

## UUID Support

This gem uses UUIDs for the tenant model by default to ensure proper multi-tenant isolation. The `enable_uuid` migration must be run before creating tenant tables.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
