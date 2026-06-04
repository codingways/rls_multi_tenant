# frozen_string_literal: true

require 'ipaddr'

module RlsMultiTenant
  module Middleware
    class SubdomainTenantSelector
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        tenant = resolve_tenant_from_subdomain(request)

        if tenant
          handle_tenant_request(env, request, tenant)
        else
          handle_no_tenant_request(env, request)
        end
      end

      private

      def handle_tenant_request(env, request, tenant)
        log_tenant_access(request, tenant)
        RlsMultiTenant.tenant_class.switch(tenant) do
          @app.call(env)
        end
      end

      def handle_no_tenant_request(env, request)
        subdomain = extract_subdomain(request.host)

        if subdomain.present? && !excluded_subdomain?(subdomain)
          handle_missing_tenant_error(request, subdomain)
        else
          handle_public_access(request)
          @app.call(env)
        end
      end

      def log_tenant_access(request, tenant)
        return unless defined?(Rails)

        Rails.logger.info "[RLS Multi-Tenant] #{request.method} #{request.path} -> Tenant: #{tenant.name} (#{tenant.id})"
      end

      def handle_missing_tenant_error(request, subdomain)
        log_missing_tenant_warning(request, subdomain)
        raise RlsMultiTenant::Error,
              "No tenant found for subdomain '#{subdomain}'. Please ensure the tenant exists with the correct subdomain."
      end

      def log_missing_tenant_warning(request, subdomain)
        return unless defined?(Rails)

        Rails.logger.warn "[RLS Multi-Tenant] #{request.method} #{request.path} -> No tenant found for subdomain '#{subdomain}'"
      end

      def handle_public_access(request)
        return unless defined?(Rails)

        Rails.logger.info "[RLS Multi-Tenant] #{request.method} #{request.path} -> Public access (no subdomain)"
      end

      def resolve_tenant_from_subdomain(request)
        subdomain = extract_subdomain(request.host)
        return nil if subdomain.blank? || excluded_subdomain?(subdomain)

        # Look up tenant by subdomain only
        tenant_class = RlsMultiTenant.tenant_class
        subdomain_field = RlsMultiTenant.subdomain_field

        # Only allow subdomain-based lookup
        unless tenant_class.column_names.include?(subdomain_field.to_s)
          raise RlsMultiTenant::ConfigurationError,
                "Subdomain field '#{subdomain_field}' not found on #{tenant_class.name}. " \
                "Please add a '#{subdomain_field}' column to your tenant model or configure a different subdomain_field."
        end

        tenant_class.find_by(subdomain_field => subdomain)
      rescue StandardError => e
        Rails.logger.error "Failed to resolve tenant from subdomain '#{subdomain}': #{e.message}" if defined?(Rails)
        nil
      end

      def extract_subdomain(host)
        return nil if host.blank?

        hostname = extract_hostname(host)
        return nil if hostname.blank? || ip_host?(hostname)

        # Split by dots and get the first part (subdomain)
        parts = hostname.split('.')

        # Handle localhost development (e.g., foo.localhost:3000) or standard domains (e.g., foo.example.com)
        return unless (parts.length == 2 && parts.last == 'localhost') || parts.length >= 3

        parts.first
      end

      # Strip an optional :port and IPv6 brackets, returning the bare hostname or
      # IP literal. Handles host, host:port, ipv4, ipv4:port, [ipv6], [ipv6]:port
      # and bare ipv6.
      def extract_hostname(host)
        if host.start_with?('[') # [ipv6] or [ipv6]:port
          host[/\A\[(.+?)\]/, 1]
        elsif host.count(':') > 1 # bare ipv6 (no port)
          host
        else # hostname or ipv4, optionally with :port
          host.split(':').first
        end
      end

      def ip_host?(hostname)
        return false if hostname.blank?

        IPAddr.new(hostname)
        true
      rescue IPAddr::InvalidAddressError
        false
      end

      def excluded_subdomain?(subdomain)
        return false if subdomain.blank?

        excluded = RlsMultiTenant.excluded_subdomains
        excluded.is_a?(Array) && excluded.include?(subdomain.to_s.downcase)
      end
    end
  end
end
