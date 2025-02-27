# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  jti                    :string
#  confirmation_code      :string
#  confirmed_at           :datetime
#  name                   :string
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable, :jwt_authenticatable, jwt_revocation_strategy: self

  # rubocop:disable Lint/LiteralAsCondition
  devise :confirmable if :email_verification_enabled?
  # rubocop:enable Lint/LiteralAsCondition

  before_create :assign_unique_id

  attr_accessor :company_name

  validates :email, presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  VALID_PASSWORD_REGEX = /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[^\w\s]).{8,128}$/
  validates :email, format: { with: VALID_EMAIL_REGEX }
  validate :password_complexity

  enum :status, %i[active invited expired]

  has_many :workspace_users, dependent: :nullify
  has_many :workspaces, through: :workspace_users
  has_many :roles, through: :workspace_users

  # Checks if email verification is enabled
  # Note: Checking for 'false' instead of 'true' ensures backward compatibility
  # with existing deployments that don't have this environment variable set.
  # This way, email verification remains enabled by default unless explicitly disabled.
  def self.email_verification_enabled?
    ENV["USER_EMAIL_VERIFICATION"] != "false"
  end

  # This method checks whether the JWT token is revoked
  def self.jwt_revoked?(payload, user)
    user.jti != payload["jti"]
  end

  # This method revokes the JWT token
  def self.revoke_jwt(_payload, user)
    user.update!(jti: nil)
  end

  def verified?
    confirmed_at.present?
  end

  protected

  def confirmation_required?
    User.email_verification_enabled?
  end

  private

  def assign_unique_id
    self.unique_id = SecureRandom.uuid
  end

  def password_complexity
    return if password.blank? || password =~ VALID_PASSWORD_REGEX

    errors.add :password,
               "Length should be 8-128 characters and include: 1 uppercase,lowercase,digit and special character"
  end
end
