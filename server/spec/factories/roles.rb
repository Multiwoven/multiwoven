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
FactoryBot.define do
  factory :role do
    role_name { "CustomRole" }
    policies { { "permissions" => {} } }

    trait :admin do
      role_name { "Admin" }
      role_desc { "Administrator role with full access" }
      policies do
        {
          "permissions" => {
            "sync" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "user" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "model" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "report" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "sync_run" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "connector" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "workspace" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "sync_record" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "connector_definition" => { "read" => true, "create" => true, "delete" => true, "update" => true }
          }
        }
      end
    end

    trait :member do
      role_name { "Member" }
      role_desc { "Member role with basic access" }
      policies do
        {
          "permissions" => {
            "sync" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "user" => { "read" => false, "create" => false, "delete" => false, "update" => false },
            "model" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "report" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "sync_run" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "connector" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "workspace" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "sync_record" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "connector_definition" => { "read" => true, "create" => true, "delete" => true, "update" => true }
          }
        }
      end
    end

    trait :viewer do
      role_name { "Viewer" }
      role_desc { "Viewer role with read-only access" }
      policies do
        {
          "permissions" => {
            "sync" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "user" => { "read" => false, "create" => false, "delete" => false, "update" => false },
            "model" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "report" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "sync_run" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "connector" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "workspace" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "sync_record" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "connector_definition" => { "read" => true, "create" => false, "delete" => false, "update" => false }
          }
        }
      end
    end
  end
end
