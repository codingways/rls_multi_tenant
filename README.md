# RLS Multi-Tenant

A Rails gem that provides PostgreSQL Row Level Security (RLS) based multi-tenancy for Rails applications.

## Features

- 🔒 **Row Level Security**: Automatic tenant isolation using PostgreSQL RLS
- 🛡️ **Security Validation**: Prevents running with privileged database users
- 🔄 **Context Switching**: Easy tenant context management
- 📦 **Auto-inclusion**: Automatic model configuration
- 🚀 **Generators**: Rails generators for quick setup
- ⚙️ **Configurable**: Flexible configuration options

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rls_multi_tenant', path: 'gems/rls_multi_tenant'
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

2. **Configure environment variables:**
   ```bash
   POSTGRES_USER=your_admin_user # This is the user that will run the migrations
   POSTGRES_PASSWORD=your_admin_user_password
   POSTGRES_APP_USER=your_app_user # This is the user that will run the app
   POSTGRES_APP_PASSWORD=your_password
   ```

3. **Run migrations:**
   ```bash
   rails db_as:admin[migrate] # Custom rake task to run migrations with admin privileges
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
  # include RlsMultiTenant::Concerns::MultiTenant
end
```

### Tenant Context Switching

```ruby
# Create a new tenant
tenant = Tenant.create!(name: "Tenant 1")
```

```ruby
# Switch tenant context for a block
Tenant.switch(tenant) do
  User.create!(name: "User from Tenant 1", email: "user@example.com") # Automatically assigned to current tenant
end

# Switch tenant context permanently
Tenant.switch!(tenant)
User.create!(name: "User from Tenant 1", email: "user@example.com")
Tenant.reset! # Reset context

# Get current tenant
current_tenant = Tenant.current
```

## Configuration

Configure the gem in `config/initializers/rls_multi_tenant.rb`:

```ruby
RlsMultiTenant.configure do |config|
  config.tenant_class_name = "Tenant"           # Your tenant model class
  config.tenant_id_column = :tenant_id          # Tenant ID column name
  config.app_user_env_var = "POSTGRES_APP_USER" # Environment variable for app user
  config.enable_security_validation = true      # Enable security checks. This will check if the app user is set without superuser privileges.
end
```

### Database Admin Task
```bash
# Run migrations with admin privileges (required because app user can't run migrations)
rails db_as:admin[migrate]

# Run seeds with admin privileges
rails db_as:admin[seed]

# Create database with admin privileges
rails db_as:admin[create]
```

## Security Features

The gem includes multiple security layers:

1. **Environment Validation**: Ensures `POSTGRES_APP_USER` is set and not privileged
2. **Database User Validation**: Checks that the database user doesn't have SUPERUSER privileges
3. **RLS Policies**: Automatic tenant isolation at the database level

## Requirements

- Rails 7.0+
- PostgreSQL 12+ (with UUID extension support)
- Ruby 3.0+

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
