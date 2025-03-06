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
    role_name { "System Role" }
    role_type { 1 }
    policies { { "permissions" => {} } }

    trait :admin do
      role_name { "Admin" }
      role_desc { "Administrator role with full access" }
      role_type { 1 }
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
            "connector_definition" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "data_app" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "audit_logs" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "alerts" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "billing" => { "create" => true, "read" => true, "update" => true, "delete" => true },
            "sso": { "create": true, "read": true, "update": true, "delete": true }
          }
        }
      end
    end

    trait :member do
      role_name { "Member" }
      role_desc { "Member role with basic access" }
      role_type { 1 }
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
            "connector_definition" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "data_app" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "audit_logs" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "alerts" => { "read" => true, "create" => true, "delete" => true, "update" => true },
            "billing" => { "create" => false, "read" => false, "update" => false, "delete" => false },
            "sso": { "create" => false, "read" => false, "update" => false, "delete" => false }
          }
        }
      end
    end

    trait :viewer do
      role_name { "Viewer" }
      role_desc { "Viewer role with read-only access" }
      role_type { 1 }
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
            "connector_definition" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "data_app" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "audit_logs" => { "read" => false, "create" => false, "delete" => false, "update" => false },
            "alerts" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "billing" => { "create" => false, "read" => false, "update" => false, "delete" => false },
            "sso": { "create" => false, "read" => false, "update" => false, "delete" => false }
          }
        }
      end
    end

    trait :custom do
      role_name { "Custom Role" }
      role_desc { "Viewer role with read-only access" }
      role_type { 0 }
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
            "connector_definition" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "data_app" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "audit_logs" => { "read" => false, "create" => false, "delete" => false, "update" => false },
            "alerts" => { "read" => true, "create" => false, "delete" => false, "update" => false },
            "billing" => { "create" => false, "read" => false, "update" => false, "delete" => false },
            "sso": { "create" => false, "read" => false, "update" => false, "delete" => false }
          }
        }
      end
    end
  end
end
