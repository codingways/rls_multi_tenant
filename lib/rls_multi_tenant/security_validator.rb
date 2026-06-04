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
          ensure_no_bypassrls!(username)

          Rails.logger&.info "✅ RLS Multi-tenant security check passed: Using user '#{username}' " \
                             'without SUPERUSER or BYPASSRLS privileges'
        rescue StandardError => e
          Rails.logger&.error "❌ RLS Multi-tenant security check failed: #{e.message}"
          raise e
        end
      end

      private

      # Inspect the actual connected role (current_user), not the configured
      # username, so the check reflects what PostgreSQL really enforces and
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

      # BYPASSRLS can also be inherited through role membership, so check the
      # effective privilege across every role the user is a member of.
      def ensure_no_bypassrls!(username)
        return unless bypassrls_effective?

        raise SecurityError, "Database user '#{username}' has BYPASSRLS privilege " \
                             '(directly or through an inherited role). ' \
                             'In order to use RLS Multi-tenant, you must use a non-privileged user ' \
                             'without BYPASSRLS privilege.'
      end

      def bypassrls_effective?
        result = ActiveRecord::Base.connection.execute(<<~SQL.squish).first
          SELECT bool_or(rolbypassrls) AS bypass
          FROM pg_roles WHERE pg_has_role(current_user, oid, 'USAGE')
        SQL

        truthy?(result && result['bypass'])
      end

      # PostgreSQL boolean columns may come back as true/false or 't'/'f'
      # depending on the adapter/decoder configuration.
      def truthy?(value)
        TRUTHY_VALUES.include?(value)
      end
    end
  end
end
