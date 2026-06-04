# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RlsMultiTenant::Middleware::SubdomainTenantSelector do
  subject(:middleware) { described_class.new(->(_env) { [200, {}, ['OK']] }) }

  describe '#extract_subdomain' do
    {
      'acme.example.com' => 'acme',
      'a.b.example.com' => 'a',
      'www.example.com' => 'www',
      'foo.localhost' => 'foo',
      'foo.localhost:3000' => 'foo',
      'example.com' => nil,
      'localhost' => nil,
      'localhost:3000' => nil,
      '127.0.0.1' => nil,
      '127.0.0.1:3000' => nil,
      '::1' => nil,
      '[::1]' => nil,
      '[::1]:3000' => nil,
      '' => nil
    }.each do |host, expected|
      it "returns #{expected.inspect} for #{host.inspect}" do
        expect(middleware.send(:extract_subdomain, host)).to eq(expected)
      end
    end
  end

  describe '#ip_host?' do
    %w[127.0.0.1 10.0.0.1 ::1 2001:db8::1].each do |host|
      it "treats #{host} as an IP" do
        expect(middleware.send(:ip_host?, host)).to be(true)
      end
    end

    %w[example.com localhost acme].each do |host|
      it "does not treat #{host} as an IP" do
        expect(middleware.send(:ip_host?, host)).to be(false)
      end
    end
  end

  describe '#excluded_subdomain?' do
    before { allow(RlsMultiTenant).to receive(:excluded_subdomains).and_return(%w[www admin]) }

    it 'matches configured subdomains case-insensitively' do
      expect(middleware.send(:excluded_subdomain?, 'WWW')).to be(true)
      expect(middleware.send(:excluded_subdomain?, 'admin')).to be(true)
    end

    it 'does not match other subdomains' do
      expect(middleware.send(:excluded_subdomain?, 'acme')).to be(false)
    end

    it 'returns false for a blank subdomain' do
      expect(middleware.send(:excluded_subdomain?, '')).to be(false)
    end
  end
end
