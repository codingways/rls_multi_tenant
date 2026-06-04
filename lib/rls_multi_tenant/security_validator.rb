# frozen_string_literal: true

module RlsMultiTenant
  class SecurityValidator
    TRUTHY_VALUES = [true, 't'].freeze

    class << self
      def validate_database_user!
        return unless RlsMultiTenant.enable_security_validation

        begin
          role = current_role
          username = role && role['username']

          ensure_not_superuser!(role, username)
          ensure_no_bypassrls!(role, username)

          Rails.logger&.info "✅ RLS Multi-tenant security check passed: Using user '#{username}' " \
                             'without SUPERUSER or BYPASSRLS privileges'
        rescue StandardError => e
          Rails.logger&.error "❌ RLS Multi-tenant security check failed: #{e.message}"
          raise e
        end
      end

      private

      # Inspect the actual connected role (current_user). Only this role's own
      # attributes determine whether RLS is enforced: PostgreSQL does NOT
      # inherit SUPERUSER or BYPASSRLS through role membership, so checking the
      # current role is both correct and sufficient. Using current_user also
      # avoids interpolating a config value into SQL.
      def current_role
        ActiveRecord::Base.connection.execute(<<~SQL.squish).first
          SELECT current_user AS username, rolsuper, rolbypassrls
          FROM pg_roles WHERE rolname = current_user
        SQL
      end

      # A SUPERUSER bypasses RLS unconditionally, regardless of the rolbypassrls
      # flag, so it must be rejected explicitly.
      def ensure_not_superuser!(role, username)
        return unless truthy?(role && role['rolsuper'])

        raise SecurityError, "Database user '#{username}' is a SUPERUSER. " \
                             'Superusers bypass Row Level Security entirely. You must use a ' \
                             'non-privileged, non-superuser role for RLS Multi-tenant.'
      end

      def ensure_no_bypassrls!(role, username)
        return unless truthy?(role && role['rolbypassrls'])

        raise SecurityError, "Database user '#{username}' has BYPASSRLS privilege. " \
                             'In order to use RLS Multi-tenant, you must use a non-privileged user ' \
                             'without BYPASSRLS privilege.'
      end

      # PostgreSQL boolean columns may come back as true/false or 't'/'f'
      # depending on the adapter/decoder configuration.
      def truthy?(value)
        TRUTHY_VALUES.include?(value)
      end
    end
  end
end
