# frozen_string_literal: true

class CreateSuperAdminService
  def self.create_default_admin(email:, password:, name: "SuperAdmin")
    # Check if admin exists to prevent duplicates
    return if SuperAdmin.exists?(email: email)

    SuperAdmin.create!(
      email: email,
      password: password,
      password_confirmation: password,
      name: name
    )
  end
end
