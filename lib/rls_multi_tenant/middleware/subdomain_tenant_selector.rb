# frozen_string_literal: true

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
          # Switch tenant context for the duration of the request
          Rails.logger.info "[RLS Multi-Tenant] #{request.method} #{request.path} -> Tenant: #{tenant.name} (#{tenant.id})" if defined?(Rails)
          RlsMultiTenant.tenant_class.switch(tenant) do
            @app.call(env)
          end
        else
          # No tenant found - check if we need tenant context
          subdomain = extract_subdomain(request.host)
          if subdomain.present? && subdomain != 'www'
            # Subdomain exists but no tenant found - this is an error
            Rails.logger.warn "[RLS Multi-Tenant] #{request.method} #{request.path} -> No tenant found for subdomain '#{subdomain}'" if defined?(Rails)
            raise RlsMultiTenant::Error, "No tenant found for subdomain '#{subdomain}'. Please ensure the tenant exists with the correct subdomain."
          end
          # If no subdomain, allow access to public models (models without TenantContext)
          # Models that include TenantContext will automatically be constrained by RLS
          Rails.logger.info "[RLS Multi-Tenant] #{request.method} #{request.path} -> Public access (no subdomain)" if defined?(Rails)
          @app.call(env)
        end
      end

      private

      def resolve_tenant_from_subdomain(request)
        subdomain = extract_subdomain(request.host)
        return nil if subdomain.blank? || subdomain == 'www'

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
      rescue => e
        Rails.logger.error "Failed to resolve tenant from subdomain '#{subdomain}': #{e.message}" if defined?(Rails)
        nil
      end

      def extract_subdomain(host)
        return nil if host.blank?
        
        # Remove port if present
        host = host.split(':').first
        
        # Split by dots and get the first part (subdomain)
        parts = host.split('.')
        
        # Handle localhost development (e.g., foo.localhost:3000)
        if parts.length == 2 && parts.last == 'localhost'
          parts.first
        # Handle standard domains (e.g., foo.example.com)
        elsif parts.length >= 3
          parts.first
        else
          nil
        end
      end
    end
  end
end
