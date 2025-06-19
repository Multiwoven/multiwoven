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

end
