# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id                :bigint           not null, primary key
#  role_name         :string
#  role_desc         :string
#  policies          :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Role < ApplicationRecord
  validates :role_name, presence: true
  validates :policies, presence: true

  enum role_type: { custom: 0, system: 1 }

  belongs_to :organization, optional: true
end
