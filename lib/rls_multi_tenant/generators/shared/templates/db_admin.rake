namespace :db_as do
  desc "Run a db: task with admin privileges. Usage: `rails db_as:admin[migrate]`"
  task :admin, [:sub_task] do |t, args|
    sub_task = args[:sub_task]

    # Check if a sub-task was provided
    if sub_task.nil? || !Rake::Task.task_defined?("db:#{sub_task}")
      puts "Usage: rails db_as:admin[sub_task]"
      puts "Valid sub-tasks: #{Rake.application.tasks.map(&:name).select { |name| name.start_with?("db:") }.map { |name| name.split(':', 2).last }.uniq.sort.join(', ')}"
      exit
    end

    database_url = "postgresql://#{ENV['POSTGRES_USER']}:#{ENV['POSTGRES_PASSWORD']}@#{ENV['POSTGRES_HOST']}:5432/#{ENV['POSTGRES_DB']}"

    # Set the DATABASE_URL with admin user details.
    ENV['DATABASE_URL'] = database_url
    ENV['CACHE_DATABASE_URL'] = "#{database_url}_cache"
    ENV['QUEUE_DATABASE_URL'] = "#{database_url}_queue"
    ENV['CABLE_DATABASE_URL'] = "#{database_url}_cable"
    
    # Set a flag to indicate we're running with admin privileges
    ENV['RLS_MULTI_TENANT_ADMIN_MODE'] = 'true'

    puts "Executing db:#{sub_task} with admin privileges..."
    Rake::Task["db:#{sub_task}"].invoke
  end
end
