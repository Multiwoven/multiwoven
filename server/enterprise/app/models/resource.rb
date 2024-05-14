# frozen_string_literal: true

# == Schema Information
#
# Table name: resources
#
#  id                :bigint           not null, primary key
#  resources_name    :string
#  permissions       :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Resource < ApplicationRecord
  validates :resources_name, presence: true
end
