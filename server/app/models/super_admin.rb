# frozen_string_literal: true

class SuperAdmin < ApplicationRecord
  has_secure_password
  
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_digest_changed?
  
  def self.authenticate(email, password)
    admin = SuperAdmin.find_by(email: email)
    admin&.authenticate(password)
  end
  
  # Finds an existing SuperAdmin by email or creates a new one
  # @param attributes [Hash] attributes for finding/creating the SuperAdmin
  #   Must include :email and :password if creating a new record
  # @return [SuperAdmin] the found or newly created SuperAdmin
  # @example
  #   SuperAdmin.find_or_create_by(email: 'admin@example.com', password: 'securepass')
  def self.find_or_create_by(attributes)
    admin = SuperAdmin.find_by(email: attributes[:email])
    return admin if admin.present?
    
    # Create new admin if not found
    SuperAdmin.create!(attributes)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create SuperAdmin: #{e.message}")
    nil
  end
end
