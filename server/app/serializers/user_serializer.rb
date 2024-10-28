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
# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :created_at, :role, :status, :invitation_created_at,
             :invitation_due_at, :email_verification_enabled

  def role
    workspace_id = instance_options[:workspace_id]
    workspace_user = object.workspace_users.find_by(workspace_id:)
    workspace_user&.role&.role_name
  end

  def invitation_due_at
    return object.invitation_due_at if object.status == "invited"

    nil
  end

  def email_verification_enabled
    User.email_verification_enabled?
  end
end
