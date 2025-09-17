# frozen_string_literal: true

# Shared examples for common test patterns

RSpec.shared_examples 'a tenant context method' do |method_name|
  it 'delegates to class method' do
    expect(described_class).to receive(method_name).with(tenant)
    instance.send(method_name, tenant)
  end
end

RSpec.shared_examples 'a generator that creates files' do |expected_files|
  expected_files.each do |file_path|
    it "creates #{file_path}" do
      expect(file(file_path)).to exist
    end
  end
end

RSpec.shared_examples 'a migration generator' do |table_name|
  it 'creates migration with correct table name' do
    migration_file = file("db/migrate/enable_rls_for_#{table_name}.rb")
    expect(migration_file).to contain("class EnableRlsFor#{table_name.camelize} < ActiveRecord::Migration")
    expect(migration_file).to contain("ALTER TABLE #{table_name} ENABLE ROW LEVEL SECURITY")
  end
end
