# frozen_string_literal: true

# Create the first SuperAdmin account
puts "Creating default SuperAdmin account..."

# Check if the SuperAdmin table exists before attempting to create a record
if ActiveRecord::Base.connection.table_exists?(:super_admins)
  # Use our service to safely create the admin
  admin = CreateSuperAdminService.create_default_admin(
    email: 'admin@audiencelab.com',
    password: 'AdminPassword123!',
    name: 'System Administrator'
  )

  puts "SuperAdmin created: #{admin.nil? ? 'already exists' : admin.email}"
else
  puts "SuperAdmins table doesn't exist yet. Run migrations first."
end
