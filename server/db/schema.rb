# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

<<<<<<< HEAD
ActiveRecord::Schema[7.1].define(version: 2025_10_09_173752) do
=======
ActiveRecord::Schema[7.2].define(version: 2026_09_12_100300) do
>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
<<<<<<< HEAD
=======
  end

  create_table "agentic_coding_app_clone_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "clone_request_id", null: false
    t.uuid "app_id"
    t.uuid "source_app_id"
    t.bigint "workspace_id", null: false
    t.bigint "source_workspace_id"
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.text "error_message"
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.string "failed_at_status"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id"], name: "index_agentic_coding_app_clone_jobs_on_app_id"
    t.index ["clone_request_id", "workspace_id"], name: "index_app_clone_jobs_on_clone_request_id_and_workspace_id", unique: true
    t.index ["source_app_id", "workspace_id"], name: "index_app_clone_jobs_in_flight_per_workspace", unique: true, where: "(status = ANY (ARRAY[0, 1, 2, 3, 4, 5]))"
    t.index ["source_app_id"], name: "index_agentic_coding_app_clone_jobs_on_source_app_id"
    t.index ["source_workspace_id"], name: "index_agentic_coding_app_clone_jobs_on_source_workspace_id"
    t.index ["status"], name: "index_agentic_coding_app_clone_jobs_on_status"
    t.index ["user_id"], name: "index_agentic_coding_app_clone_jobs_on_user_id"
    t.index ["workspace_id"], name: "index_agentic_coding_app_clone_jobs_on_workspace_id"
  end

  create_table "agentic_coding_app_git_targets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "app_id", null: false
    t.uuid "git_target_id", null: false
    t.string "branch", null: false
    t.string "last_commit"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id"], name: "index_agentic_coding_app_git_targets_on_app_id", unique: true
    t.index ["git_target_id", "branch"], name: "index_app_git_targets_on_target_and_branch", unique: true
    t.index ["git_target_id"], name: "index_agentic_coding_app_git_targets_on_git_target_id"
    t.index ["status"], name: "index_agentic_coding_app_git_targets_on_status"
  end

  create_table "agentic_coding_app_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "agentic_coding_app_id", null: false
    t.string "resource_type", null: false
    t.string "resource_id"
    t.text "credentials", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "status", default: "provisioning", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agentic_coding_app_id", "resource_type"], name: "idx_agentic_app_resources_active_type_per_app", unique: true, where: "((status)::text <> 'deleted'::text)"
    t.index ["agentic_coding_app_id"], name: "index_agentic_coding_app_resources_on_agentic_coding_app_id"
    t.index ["resource_type"], name: "index_agentic_coding_app_resources_on_resource_type"
  end

  create_table "agentic_coding_app_secrets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "agentic_coding_app_id", null: false
    t.string "name", null: false
    t.text "value", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "agentic_coding_app_id, lower((name)::text)", name: "index_app_secrets_on_app_id_and_name", unique: true
    t.index ["agentic_coding_app_id"], name: "index_agentic_coding_app_secrets_on_agentic_coding_app_id"
  end

  create_table "agentic_coding_app_users", force: :cascade do |t|
    t.uuid "app_id", null: false
    t.bigint "user_id", null: false
    t.bigint "invited_by_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id", "user_id"], name: "index_agentic_coding_app_users_on_app_id_and_user_id", unique: true
    t.index ["app_id"], name: "index_agentic_coding_app_users_on_app_id"
    t.index ["invited_by_id"], name: "index_agentic_coding_app_users_on_invited_by_id"
    t.index ["user_id"], name: "index_agentic_coding_app_users_on_user_id"
  end

  create_table "agentic_coding_app_visitors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "visitor_token", null: false
    t.uuid "app_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "deployment_id"
    t.index ["app_id"], name: "index_agentic_coding_app_visitors_on_app_id"
    t.index ["deployment_id"], name: "index_agentic_coding_app_visitors_on_deployment_id"
    t.index ["visitor_token", "app_id", "deployment_id"], name: "idx_app_visitors_on_token_app_deployment", unique: true
  end

  create_table "agentic_coding_apps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.bigint "user_id", null: false
    t.string "name"
    t.text "description"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "template_id"
    t.uuid "source_app_id"
    t.string "slug"
    t.boolean "show_badge", default: true, null: false
    t.integer "visibility", default: 1, null: false
    t.string "app_token"
    t.datetime "unpublished_at"
    t.index ["app_token"], name: "index_agentic_coding_apps_on_app_token", unique: true
    t.index ["slug"], name: "index_agentic_coding_apps_on_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index ["source_app_id"], name: "index_agentic_coding_apps_on_source_app_id"
    t.index ["template_id"], name: "index_agentic_coding_apps_on_template_id"
    t.index ["user_id"], name: "index_agentic_coding_apps_on_user_id"
    t.index ["workspace_id"], name: "index_agentic_coding_apps_on_workspace_id"
  end

  create_table "agentic_coding_deployments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "agentic_coding_app_id", null: false
    t.uuid "agentic_coding_session_id", null: false
    t.bigint "workspace_id", null: false
    t.integer "status", default: 0, null: false
    t.string "deploy_url"
    t.string "deploy_target"
    t.string "commit_sha"
    t.string "version_tag"
    t.jsonb "deploy_metadata"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "neon_deployed_at"
    t.integer "version_number"
    t.text "version_description"
    t.datetime "deployed_at"
    t.bigint "version_author_id"
    t.index ["agentic_coding_app_id", "version_number"], name: "idx_deployments_on_app_id_and_version_number", unique: true, where: "(version_number IS NOT NULL)"
    t.index ["agentic_coding_app_id"], name: "index_agentic_coding_deployments_on_agentic_coding_app_id"
    t.index ["agentic_coding_session_id"], name: "index_agentic_coding_deployments_on_agentic_coding_session_id"
    t.index ["version_author_id"], name: "idx_deployments_on_version_author_id"
    t.index ["workspace_id"], name: "index_agentic_coding_deployments_on_workspace_id"
  end

  create_table "agentic_coding_prompts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "agentic_coding_app_id", null: false
    t.uuid "agentic_coding_session_id", null: false
    t.integer "role"
    t.text "content"
    t.integer "status", default: 0, null: false
    t.text "response_text"
    t.string "agent_mode"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "context", default: {}, null: false
    t.text "urls", default: [], null: false, array: true
    t.integer "prompt_type", default: 0, null: false
    t.string "message_id"
    t.string "part_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "user_id"
    t.index ["agentic_coding_app_id"], name: "index_agentic_coding_prompts_on_agentic_coding_app_id"
    t.index ["agentic_coding_session_id", "message_id", "started_at"], name: "idx_agentic_prompts_on_session_message_started"
    t.index ["agentic_coding_session_id", "part_id"], name: "idx_agentic_prompts_on_session_part_unique", unique: true, where: "(part_id IS NOT NULL)"
    t.index ["agentic_coding_session_id"], name: "index_agentic_coding_prompts_on_agentic_coding_session_id"
    t.index ["created_at"], name: "index_agentic_coding_prompts_in_flight_on_created_at", where: "(status = ANY (ARRAY[0, 1]))"
    t.index ["user_id"], name: "index_agentic_coding_prompts_on_user_id"
  end

  create_table "agentic_coding_security_findings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "agentic_coding_app_id", null: false
    t.string "fingerprint", null: false
    t.string "tool", null: false
    t.string "rule", null: false
    t.string "package"
    t.integer "scope"
    t.jsonb "references", default: [], null: false
    t.uuid "first_detected_scan_id", null: false
    t.uuid "last_detected_scan_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "severity", null: false
    t.string "title", null: false
    t.text "description"
    t.string "category"
    t.jsonb "tags", default: [], null: false
    t.jsonb "location"
    t.text "remediation"
    t.uuid "resolving_prompt_id"
    t.integer "reopened_count", default: 0, null: false
    t.datetime "first_detected_at", null: false
    t.datetime "last_detected_at", null: false
    t.datetime "resolved_at"
    t.bigint "ignored_by_user_id"
    t.datetime "ignored_at"
    t.text "ignore_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agentic_coding_app_id", "fingerprint"], name: "index_agentic_coding_security_findings_on_app_and_fingerprint", unique: true
    t.index ["agentic_coding_app_id", "status"], name: "index_agentic_coding_security_findings_on_app_and_status"
    t.index ["agentic_coding_app_id"], name: "idx_on_agentic_coding_app_id_a14bc21bff"
    t.index ["first_detected_scan_id"], name: "idx_on_first_detected_scan_id_02a0e3c4d8"
    t.index ["ignored_by_user_id"], name: "index_agentic_coding_security_findings_on_ignored_by_user_id"
    t.index ["last_detected_scan_id"], name: "idx_on_last_detected_scan_id_85cb28f62d"
    t.index ["resolving_prompt_id"], name: "index_agentic_coding_security_findings_on_resolving_prompt_id"
  end

  create_table "agentic_coding_security_scans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "agentic_coding_app_id", null: false
    t.uuid "agentic_coding_session_id"
    t.bigint "workspace_id", null: false
    t.bigint "triggered_by_user_id"
    t.uuid "deployment_id"
    t.integer "status", default: 0, null: false
    t.string "engine", null: false
    t.integer "critical_count", default: 0, null: false
    t.integer "warning_count", default: 0, null: false
    t.string "error_message"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agentic_coding_app_id"], name: "index_agentic_coding_security_scans_in_flight", unique: true, where: "(status = ANY (ARRAY[0, 1]))"
    t.index ["agentic_coding_app_id"], name: "index_agentic_coding_security_scans_on_agentic_coding_app_id"
    t.index ["agentic_coding_session_id"], name: "idx_on_agentic_coding_session_id_8fe1618784"
    t.index ["deployment_id"], name: "index_agentic_coding_security_scans_on_deployment_id"
    t.index ["triggered_by_user_id"], name: "index_agentic_coding_security_scans_on_triggered_by_user_id"
    t.index ["workspace_id"], name: "index_agentic_coding_security_scans_on_workspace_id"
  end

  create_table "agentic_coding_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "agentic_coding_app_id", null: false
    t.bigint "workspace_id", null: false
    t.bigint "user_id", null: false
    t.string "title"
    t.integer "status", default: 0, null: false
    t.string "sandbox_id"
    t.string "coding_agent_session_id"
    t.string "preview_url"
    t.datetime "last_active_at"
    t.datetime "suspended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "configuration", default: {}
    t.string "agent_model"
    t.index ["agentic_coding_app_id"], name: "index_agentic_coding_sessions_on_agentic_coding_app_id"
    t.index ["user_id"], name: "index_agentic_coding_sessions_on_user_id"
    t.index ["workspace_id"], name: "index_agentic_coding_sessions_on_workspace_id"
  end

  create_table "agentic_coding_template_sync_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "manifest", null: false
    t.string "status", default: "queued", null: false
    t.jsonb "diff"
    t.text "error_message"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_agentic_coding_template_sync_jobs_on_status"
  end

  create_table "agentic_coding_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "image_id", null: false
    t.string "repo_url"
    t.string "category"
    t.string "icon"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "prompt"
    t.string "docker_image"
    t.string "slug"
    t.string "source_commit"
    t.datetime "image_built_at"
    t.index ["category"], name: "index_agentic_coding_templates_on_category"
    t.index ["name"], name: "index_agentic_coding_templates_on_name", unique: true
    t.index ["slug"], name: "index_agentic_coding_templates_on_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index ["status"], name: "index_agentic_coding_templates_on_status"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
  end

  create_table "alert_channels", force: :cascade do |t|
    t.bigint "alert_id", null: false
    t.jsonb "configuration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "alert_medium_id", null: false
    t.index ["alert_id"], name: "index_alert_channels_on_alert_id"
    t.index ["alert_medium_id"], name: "index_alert_channels_on_alert_medium_id"
  end

  create_table "alert_media", force: :cascade do |t|
    t.string "name"
    t.integer "platform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "logo"
  end

  create_table "alerts", force: :cascade do |t|
    t.string "name"
    t.bigint "workspace_id", null: false
    t.boolean "alert_sync_success", default: false
    t.boolean "alert_sync_failure", default: false
    t.boolean "alert_row_failure", default: false
    t.integer "row_failure_threshold_percent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_run_at"
    t.index ["workspace_id"], name: "index_alerts_on_workspace_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.integer "user_id"
    t.string "action", null: false
    t.string "resource_type", null: false
    t.integer "resource_id"
    t.string "resource"
    t.integer "workspace_id"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "resource_link"
  end

  create_table "billing_plans", force: :cascade do |t|
    t.string "name", null: false
    t.integer "status", default: 0
    t.float "amount", default: 0.0
    t.integer "currency", default: 0
    t.integer "interval", default: 0
    t.integer "max_data_app_sessions"
    t.integer "max_feedback_count", default: 0
    t.integer "max_rows_synced", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "addons", default: {}, null: false
  end

  create_table "billing_subscriptions", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "plan_id", null: false
    t.integer "status", default: 0
    t.integer "data_app_sessions", default: 0
    t.integer "feedback_count", default: 0
    t.integer "rows_synced", default: 0
    t.jsonb "addons_usage", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_billing_subscriptions_on_organization_id"
    t.index ["plan_id"], name: "index_billing_subscriptions_on_plan_id"
  end

  create_table "catalogs", force: :cascade do |t|
    t.integer "workspace_id"
    t.integer "connector_id"
    t.jsonb "catalog"
    t.string "catalog_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.bigint "data_app_session_id", null: false
    t.bigint "visual_component_id", null: false
    t.text "content", null: false
    t.integer "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
<<<<<<< HEAD
    t.index ["data_app_session_id", "created_at"], name: "index_chat_messages_on_data_app_session_id_and_created_at"
    t.index ["data_app_session_id"], name: "index_chat_messages_on_data_app_session_id"
=======
    t.string "session_type"
    t.uuid "workflow_id"
    t.bigint "workflow_file_id"
    t.index ["session_id", "created_at"], name: "index_chat_messages_on_session_id_and_created_at"
    t.index ["session_id"], name: "index_chat_messages_on_session_id"
    t.index ["session_type", "session_id"], name: "index_chat_messages_on_session_type_and_session_id"
>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
    t.index ["visual_component_id"], name: "index_chat_messages_on_visual_component_id"
    t.index ["workspace_id"], name: "index_chat_messages_on_workspace_id"
  end

  create_table "components", id: :string, force: :cascade do |t|
    t.integer "workspace_id", null: false
    t.uuid "workflow_id", null: false
    t.integer "component_type", null: false
    t.jsonb "configuration", null: false
    t.jsonb "position", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.jsonb "data", default: {}, null: false
    t.integer "component_category", default: 0, null: false
  end

  create_table "connectors", force: :cascade do |t|
    t.integer "workspace_id"
    t.integer "connector_type"
    t.integer "connector_definition_id"
    t.jsonb "configuration"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "connector_name"
    t.string "description"
    t.string "connector_category", default: "data", null: false
    t.string "connector_sub_category", default: "database", null: false
  end

  create_table "custom_visual_component_files", force: :cascade do |t|
    t.string "file_name"
    t.integer "workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_app_sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.bigint "data_app_id", null: false
    t.integer "workspace_id", null: false
    t.datetime "start_time", null: false
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["data_app_id"], name: "index_data_app_sessions_on_data_app_id"
    t.index ["session_id"], name: "index_data_app_sessions_on_session_id", unique: true
  end

  create_table "data_apps", force: :cascade do |t|
    t.string "name", null: false
    t.integer "status", null: false
    t.integer "workspace_id", null: false
    t.text "description"
    t.json "meta_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "data_app_token"
    t.integer "rendering_type"
    t.integer "data_app_sessions_count", default: 0, null: false
    t.integer "feedbacks_count", default: 0, null: false
    t.integer "message_feedbacks_count", default: 0, null: false
    t.integer "chat_messages_count", default: 0, null: false
    t.index ["data_app_token"], name: "index_data_apps_on_data_app_token", unique: true
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "edges", force: :cascade do |t|
    t.uuid "workflow_id", null: false
    t.integer "workspace_id", null: false
    t.string "source_component_id", null: false
    t.string "target_component_id", null: false
    t.jsonb "source_handle", null: false
    t.jsonb "target_handle", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "embedding_models", force: :cascade do |t|
    t.string "mode", null: false
    t.integer "status", default: 1
    t.string "models", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "eulas", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "file_name"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "feedbacks", force: :cascade do |t|
    t.integer "workspace_id", null: false
    t.integer "data_app_id", null: false
    t.integer "visual_component_id", null: false
    t.integer "reaction"
    t.json "feedback_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "feedback_type", default: 0, null: false
    t.string "session_id"
    t.jsonb "additional_remarks"
  end

<<<<<<< HEAD
=======
  create_table "git_installations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", default: "github", null: false
    t.bigint "external_id"
    t.string "name"
    t.integer "account_type"
    t.string "status", default: "active", null: false
    t.bigint "provider_user_id"
    t.jsonb "provider_metadata", default: {}, null: false
    t.text "cached_token"
    t.datetime "token_expires_at"
    t.text "user_token"
    t.text "refresh_token"
    t.datetime "refresh_token_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "external_id", "user_id"], name: "index_git_installations_on_provider_external_id_and_user_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["provider", "provider_user_id"], name: "index_git_installations_on_provider_and_provider_user_id", where: "(provider_user_id IS NOT NULL)"
    t.index ["provider", "user_id", "name"], name: "index_git_installations_on_provider_user_and_name", unique: true, where: "(name IS NOT NULL)"
    t.index ["user_id", "provider"], name: "index_git_installations_pending_per_user", unique: true, where: "((status)::text = 'pending'::text)"
    t.index ["user_id"], name: "index_git_installations_on_user_id"
  end

  create_table "git_session_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "session_id", null: false
    t.string "event", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "delivery_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id", "delivery_id"], name: "index_git_session_events_on_session_and_delivery", unique: true, where: "(delivery_id IS NOT NULL)"
    t.index ["session_id", "id"], name: "index_git_session_events_on_session_and_id"
    t.index ["session_id"], name: "index_git_session_events_on_session_id"
  end

  create_table "git_targets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "git_installation_id", null: false
    t.string "repo", null: false
    t.string "default_branch", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["git_installation_id", "repo"], name: "index_git_targets_on_install_repo", unique: true
    t.index ["git_installation_id"], name: "index_git_targets_on_git_installation_id"
    t.index ["status"], name: "index_git_targets_on_status"
  end

  create_table "git_webhook_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "delivery_id", null: false
    t.string "scope", null: false
    t.string "commit_sha"
    t.string "status", default: "pending", null: false
    t.string "webhook_event"
    t.jsonb "webhook_payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id"], name: "index_git_webhook_deliveries_on_delivery_id", unique: true
  end

  create_table "hosted_data_store_tables", force: :cascade do |t|
    t.integer "hosted_data_store_id"
    t.string "name"
    t.integer "column_count"
    t.integer "row_count"
    t.integer "size"
    t.integer "sync_enabled"
    t.integer "source_connector_id"
    t.integer "destination_connector_id"
    t.jsonb "table_schema", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hosted_data_stores", force: :cascade do |t|
    t.string "name"
    t.integer "workspace_id"
    t.integer "database_type"
    t.text "description"
    t.integer "state"
    t.integer "source_connector_id"
    t.integer "destination_connector_id"
    t.string "template_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "knowledge_base_files", force: :cascade do |t|
    t.string "name"
    t.integer "size", default: 0
    t.integer "knowledge_base_id"
    t.boolean "workflow_enabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "upload_status", default: 0
  end

  create_table "knowledge_bases", force: :cascade do |t|
    t.string "name"
    t.integer "knowledge_base_type"
    t.integer "size", default: 0
    t.jsonb "embedding_config"
    t.jsonb "storage_config"
    t.integer "source_connector_id"
    t.integer "destination_connector_id"
    t.integer "hosted_data_store_id"
    t.integer "workspace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "parser_config", default: {"parser_provider"=>"langchain"}, null: false
  end

  create_table "llm_routing_logs", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.bigint "workflow_run_id", null: false
    t.string "component_id", null: false
    t.string "prompt_hash", null: false
    t.string "selected_model", null: false
    t.string "selected_component_id", null: false
    t.string "selected_connector_id", null: false
    t.string "routing_strategy", default: "judge_llm", null: false
    t.string "optimization_mode", default: "balanced", null: false
    t.text "routing_reason"
    t.float "routing_confidence"
    t.integer "execution_time_ms"
    t.integer "routing_time_ms"
    t.boolean "is_fallback", default: false
    t.string "prompt_complexity"
    t.string "task_type"
    t.integer "estimated_tokens"
    t.jsonb "routing_metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["component_id"], name: "index_llm_routing_logs_on_component_id"
    t.index ["created_at"], name: "index_llm_routing_logs_on_created_at"
    t.index ["is_fallback"], name: "index_llm_routing_logs_on_is_fallback"
    t.index ["prompt_complexity"], name: "index_llm_routing_logs_on_prompt_complexity"
    t.index ["prompt_hash"], name: "index_llm_routing_logs_on_prompt_hash"
    t.index ["selected_model"], name: "index_llm_routing_logs_on_selected_model"
    t.index ["task_type"], name: "index_llm_routing_logs_on_task_type"
    t.index ["workflow_run_id"], name: "index_llm_routing_logs_on_workflow_run_id"
    t.index ["workspace_id"], name: "index_llm_routing_logs_on_workspace_id"
  end

  create_table "llm_usage_events", force: :cascade do |t|
    t.uuid "request_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "workspace_id", null: false
    t.bigint "user_id"
    t.bigint "role_id"
    t.integer "source", default: 0, null: false
    t.jsonb "source_ref", default: {}, null: false
    t.bigint "connector_id"
    t.string "provider", null: false
    t.string "model", null: false
    t.bigint "input_tokens", default: 0, null: false
    t.bigint "output_tokens", default: 0, null: false
    t.bigint "reasoning_tokens", default: 0, null: false
    t.bigint "cache_read_tokens", default: 0, null: false
    t.bigint "cache_write_tokens", default: 0, null: false
    t.integer "token_count_method", default: 0, null: false
    t.decimal "cost", precision: 18, scale: 10
    t.bigint "pricing_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["organization_id", "created_at"], name: "index_llm_usage_events_on_organization_id_and_created_at"
    t.index ["request_id"], name: "index_llm_usage_events_on_request_id", unique: true
    t.index ["workspace_id", "created_at"], name: "index_llm_usage_events_on_workspace_id_and_created_at"
    t.index ["workspace_id", "source", "created_at"], name: "index_llm_usage_events_on_workspace_and_source_and_created_at"
    t.check_constraint "cost IS NULL OR cost >= 0::numeric", name: "llm_usage_events_cost_non_negative"
    t.check_constraint "input_tokens >= 0 AND output_tokens >= 0 AND reasoning_tokens >= 0 AND cache_read_tokens >= 0 AND cache_write_tokens >= 0", name: "llm_usage_events_token_counts_non_negative"
  end

  create_table "llm_usage_logs", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.bigint "workflow_run_id", null: false
    t.string "component_id", null: false
    t.string "connector_id", null: false
    t.string "prompt_hash", null: false
    t.integer "estimated_input_tokens", null: false
    t.integer "estimated_output_tokens", null: false
    t.string "selected_model", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.float "total_cost", default: 0.0, null: false
    t.index ["component_id"], name: "index_llm_usage_logs_on_component_id"
    t.index ["created_at"], name: "index_llm_usage_logs_on_created_at"
    t.index ["prompt_hash"], name: "index_llm_usage_logs_on_prompt_hash"
    t.index ["selected_model"], name: "index_llm_usage_logs_on_selected_model"
    t.index ["workflow_run_id"], name: "index_llm_usage_logs_on_workflow_run_id"
    t.index ["workspace_id"], name: "index_llm_usage_logs_on_workspace_id"
  end

>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
  create_table "message_feedbacks", force: :cascade do |t|
    t.integer "workspace_id", null: false
    t.integer "data_app_id", null: false
    t.integer "visual_component_id", null: false
    t.integer "reaction"
    t.string "feedback_content"
    t.integer "feedback_type", default: 0, null: false
    t.json "chatbot_interaction", null: false
    t.jsonb "additional_remarks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "model_pricings", force: :cascade do |t|
    t.string "provider", null: false
    t.string "model", null: false
    t.decimal "input_rate", precision: 16, scale: 10, default: "0.0", null: false
    t.decimal "output_rate", precision: 16, scale: 10, default: "0.0", null: false
    t.decimal "cache_read_rate", precision: 16, scale: 10, default: "0.0", null: false
    t.decimal "cache_write_rate", precision: 16, scale: 10, default: "0.0", null: false
    t.string "currency", default: "USD", null: false
    t.integer "source", default: 0, null: false
    t.datetime "effective_from", null: false
    t.datetime "effective_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "model", "effective_from"], name: "index_model_pricings_on_provider_and_model_and_effective_from"
    t.index ["provider", "model"], name: "index_model_pricings_in_force", unique: true, where: "(effective_to IS NULL)"
  end

  create_table "models", force: :cascade do |t|
    t.string "name"
    t.integer "workspace_id"
    t.integer "connector_id"
    t.text "query"
    t.integer "query_type"
    t.string "primary_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.jsonb "configuration"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "organization_logo_filename"
  end

<<<<<<< HEAD
=======
  create_table "prompt_to_workflow_session_events", force: :cascade do |t|
    t.bigint "prompt_to_workflow_session_id", null: false
    t.integer "sequence", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["prompt_to_workflow_session_id", "sequence"], name: "idx_p2w_events_session_sequence", unique: true
    t.index ["prompt_to_workflow_session_id"], name: "idx_on_prompt_to_workflow_session_id_4fd8c9eb0e"
  end

  create_table "prompt_to_workflow_sessions", force: :cascade do |t|
    t.uuid "session_id", null: false
    t.uuid "workflow_id", null: false
    t.integer "workspace_id", null: false
    t.string "status", default: "running", null: false
    t.uuid "current_clarification_id"
    t.jsonb "state", default: {}, null: false
    t.string "temporal_workflow_id"
    t.string "temporal_run_id"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_turn", default: 0, null: false
    t.index ["expires_at"], name: "index_prompt_to_workflow_sessions_on_expires_at"
    t.index ["session_id"], name: "index_prompt_to_workflow_sessions_on_session_id", unique: true
    t.index ["status", "expires_at"], name: "idx_p2w_sessions_status_expires"
    t.index ["workflow_id"], name: "index_prompt_to_workflow_sessions_on_workflow_id"
    t.index ["workspace_id", "status"], name: "idx_p2w_sessions_workspace_status"
    t.index ["workspace_id"], name: "index_prompt_to_workflow_sessions_on_workspace_id"
  end

>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
  create_table "remote_code_executions", force: :cascade do |t|
    t.integer "workflow_run_id"
    t.integer "workspace_id", null: false
    t.string "component_id"
    t.integer "provider"
    t.integer "mode"
    t.integer "status"
    t.text "output"
    t.text "error_message"
    t.text "stdout"
    t.integer "execution_time_ms"
    t.integer "memory_used_mb"
    t.integer "cpu_time_ms"
    t.integer "billed_duration_ms"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "invocation_id", limit: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resources", force: :cascade do |t|
    t.string "resources_name"
    t.text "permissions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "role_name"
    t.string "role_desc"
    t.jsonb "policies", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role_type", default: 0, null: false
    t.integer "organization_id"
    t.index ["organization_id", "role_name"], name: "index_roles_on_organization_id_and_role_name", unique: true, where: "(organization_id IS NOT NULL)"
<<<<<<< HEAD
=======
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.text "channel"
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "spending_limit_counters", force: :cascade do |t|
    t.bigint "spending_limit_id", null: false
    t.datetime "window_start", null: false
    t.decimal "spent_cost", precision: 18, scale: 10, default: "0.0", null: false
    t.bigint "spent_tokens", default: 0, null: false
    t.bigint "request_count", default: 0, null: false
    t.integer "unpriced_requests", default: 0, null: false
    t.integer "alerted_thresholds", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spending_limit_id", "window_start"], name: "index_spending_limit_counters_on_limit_and_window_start", unique: true
    t.index ["spending_limit_id"], name: "index_spending_limit_counters_on_spending_limit_id"
    t.check_constraint "spent_cost >= 0::numeric AND spent_tokens >= 0 AND request_count >= 0 AND unpriced_requests >= 0", name: "spending_limit_counters_totals_non_negative"
  end

  create_table "spending_limits", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "workspace_id", null: false
    t.integer "level", default: 0, null: false
    t.string "name", null: false
    t.integer "scope_type", default: 0, null: false
    t.string "scope_ids", default: [], null: false, array: true
    t.string "providers", default: [], null: false, array: true
    t.string "models", default: [], null: false, array: true
    t.integer "limit_type", default: 0, null: false
    t.decimal "cost_limit", precision: 14, scale: 4
    t.bigint "token_limit"
    t.integer "period", default: 0, null: false
    t.integer "alert_thresholds", default: [80, 90], null: false, array: true
    t.integer "action_on_exhaust", default: 0, null: false
    t.boolean "enabled", default: true, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_spending_limits_on_created_by_id"
    t.index ["organization_id"], name: "index_spending_limits_on_organization_id"
    t.index ["workspace_id", "name"], name: "index_spending_limits_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_spending_limits_on_workspace_id"
    t.index ["workspace_id"], name: "index_spending_limits_one_allocation_per_workspace", unique: true, where: "(level = 1)"
    t.check_constraint "cost_limit IS NULL OR cost_limit > 0::numeric", name: "spending_limits_cost_limit_positive"
    t.check_constraint "limit_type = 0 AND cost_limit IS NOT NULL OR limit_type = 1 AND token_limit IS NOT NULL OR limit_type = 2 AND cost_limit IS NOT NULL AND token_limit IS NOT NULL", name: "spending_limits_cap_matches_limit_type"
    t.check_constraint "token_limit IS NULL OR token_limit > 0", name: "spending_limits_token_limit_positive"
  end

  create_table "sso_configurations", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "status", default: 1
    t.string "entity_id"
    t.string "acs_url"
    t.string "idp_sso_url"
    t.string "signing_certificate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sync_files", force: :cascade do |t|
    t.string "file_name"
    t.string "file_path"
    t.integer "size"
    t.datetime "file_created_date"
    t.datetime "file_modified_date"
    t.integer "workspace_id"
    t.integer "sync_id"
    t.integer "sync_run_id"
    t.integer "status"
    t.jsonb "metadata"
    t.string "file_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sync_id"], name: "index_sync_files_on_sync_id"
    t.index ["sync_run_id"], name: "index_sync_files_on_sync_run_id"
    t.index ["workspace_id"], name: "index_sync_files_on_workspace_id"
  end

  create_table "sync_records", force: :cascade do |t|
    t.integer "sync_id"
    t.integer "sync_run_id"
    t.jsonb "record"
    t.string "fingerprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "action"
    t.string "primary_key"
    t.integer "status", default: 0
    t.jsonb "logs"
    t.index ["sync_id", "fingerprint"], name: "index_sync_records_on_sync_id_and_fingerprint", unique: true
    t.index ["sync_id", "primary_key"], name: "index_sync_records_on_sync_id_and_primary_key", unique: true
  end

  create_table "sync_runs", force: :cascade do |t|
    t.integer "sync_id"
    t.integer "status"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "total_rows"
    t.integer "successful_rows"
    t.integer "failed_rows"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_offset", default: 0
    t.integer "workspace_id"
    t.integer "source_id"
    t.integer "destination_id"
    t.integer "model_id"
    t.integer "total_query_rows"
    t.datetime "discarded_at"
    t.integer "skipped_rows", default: 0
    t.integer "sync_run_type", default: 0
    t.string "workflow_run_id"
    t.index ["discarded_at"], name: "index_sync_runs_on_discarded_at"
  end

  create_table "syncs", force: :cascade do |t|
    t.integer "workspace_id"
    t.integer "source_id"
    t.integer "model_id"
    t.integer "destination_id"
    t.jsonb "configuration"
    t.integer "source_catalog_id"
    t.integer "schedule_type"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "primary_key"
    t.integer "sync_mode"
    t.integer "sync_interval"
    t.integer "sync_interval_unit"
    t.string "stream_name"
    t.string "workflow_id"
    t.datetime "discarded_at"
    t.string "cursor_field"
    t.string "current_cursor_field"
    t.string "cron_expression"
    t.string "name"
    t.index ["discarded_at"], name: "index_syncs_on_discarded_at"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "taggable_type"
    t.bigint "taggable_id"
    t.string "tagger_type"
    t.bigint "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

<<<<<<< HEAD
=======
  create_table "tools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "label"
    t.text "description"
    t.integer "tool_type", null: false
    t.jsonb "configuration", default: {}, null: false
    t.jsonb "metadata", default: {}
    t.boolean "enabled", default: true, null: false
    t.bigint "workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tools_on_name"
    t.index ["tool_type"], name: "index_tools_on_tool_type"
    t.index ["workspace_id", "name"], name: "index_tools_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_tools_on_workspace_id"
  end

  create_table "user_embed_origins", force: :cascade do |t|
    t.string "origin", null: false
    t.bigint "created_by_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "workspace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id", "organization_id", "origin"], name: "idx_uniq_user_org_wide_origin", unique: true, where: "(workspace_id IS NULL)"
    t.index ["created_by_id", "workspace_id", "origin"], name: "idx_uniq_user_workspace_origin", unique: true, where: "(workspace_id IS NOT NULL)"
    t.index ["created_by_id"], name: "index_user_embed_origins_on_created_by_id"
    t.index ["organization_id", "workspace_id"], name: "index_user_embed_origins_on_organization_id_and_workspace_id"
    t.index ["organization_id"], name: "index_user_embed_origins_on_organization_id"
    t.index ["workspace_id"], name: "index_user_embed_origins_on_workspace_id"
  end

>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti"
    t.string "confirmation_code"
    t.datetime "confirmed_at"
    t.string "name"
    t.string "unique_id"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.integer "status", default: 0
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.string "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.boolean "eula_accepted", default: false, null: false
    t.boolean "eula_enabled", default: false, null: false
    t.datetime "eula_accepted_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["jti"], name: "index_users_on_jti"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unique_id"], name: "index_users_on_unique_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

<<<<<<< HEAD
=======
  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.string "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.integer "version_number"
    t.text "version_description"
    t.jsonb "associations"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
  create_table "visual_components", force: :cascade do |t|
    t.integer "component_type", null: false
    t.string "name"
    t.integer "workspace_id", null: false
    t.integer "data_app_id", null: false
    t.integer "model_id"
    t.jsonb "properties"
    t.jsonb "feedback_config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "session_count", default: 0
    t.string "configurable_type"
    t.string "configurable_id"
    t.index ["configurable_type", "configurable_id"], name: "index_visual_components_on_configurable"
<<<<<<< HEAD
=======
  end

  create_table "workflow_approvals", force: :cascade do |t|
    t.bigint "workflow_run_id", null: false
    t.bigint "workspace_id", null: false
    t.string "component_id", null: false
    t.integer "status", default: 0, null: false
    t.text "message", null: false
    t.jsonb "input_data"
    t.string "temporal_workflow_id", null: false
    t.string "temporal_run_id", null: false
    t.bigint "resolved_by_id"
    t.text "resolution_note"
    t.datetime "timeout_at"
    t.string "timeout_action", default: "reject"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resolved_by_id"], name: "index_workflow_approvals_on_resolved_by_id"
    t.index ["status"], name: "index_workflow_approvals_on_status"
    t.index ["workflow_run_id", "component_id"], name: "idx_workflow_approvals_unique_pending", unique: true, where: "(status = 0)"
    t.index ["workflow_run_id"], name: "index_workflow_approvals_on_workflow_run_id"
    t.index ["workspace_id"], name: "index_workflow_approvals_on_workspace_id"
  end

  create_table "workflow_files", force: :cascade do |t|
    t.uuid "workflow_id", null: false
    t.bigint "data_app_session_id"
    t.string "name"
    t.integer "size", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_app_session_id"], name: "index_workflow_files_on_data_app_session_id"
    t.index ["workflow_id"], name: "index_workflow_files_on_workflow_id"
>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
  end

  create_table "workflow_integrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "metadata", null: false
    t.integer "workspace_id", null: false
    t.uuid "workflow_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "app_type", null: false
    t.jsonb "connection_configuration", null: false
  end

  create_table "workflow_logs", force: :cascade do |t|
    t.string "workflow_id", null: false
    t.integer "workflow_run_id", null: false
    t.string "input", null: false
    t.string "output"
    t.jsonb "logs", default: {}
    t.integer "workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "workflow_runs", force: :cascade do |t|
    t.uuid "workflow_id", null: false
    t.bigint "workspace_id", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "inputs", default: {}
    t.jsonb "outputs", default: {}
    t.text "error_message"
    t.string "temporal_workflow_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "finished_at"
    t.index ["workspace_id"], name: "index_workflow_runs_on_workspace_id"
  end

  create_table "workflows", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "workspace_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "status"
    t.integer "trigger_type"
    t.jsonb "configuration", default: {}
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
<<<<<<< HEAD
=======
    t.boolean "access_control_enabled", default: false, null: false
    t.jsonb "access_control", default: {}, null: false
    t.integer "version_number", default: 1
    t.integer "workflow_sessions_count", default: 0, null: false
>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
    t.index ["workspace_id", "name"], name: "index_workflows_on_workspace_id_and_name", unique: true
  end

  create_table "workspace_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "workspace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "role_id"
    t.index ["role_id"], name: "index_workspace_users_on_role_id"
    t.index ["user_id", "workspace_id", "role_id"], name: "index_workspace_users_on_user_workspace_role", unique: true
    t.index ["user_id"], name: "index_workspace_users_on_user_id"
    t.index ["workspace_id"], name: "index_workspace_users_on_workspace_id"
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "status"
    t.string "api_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.text "description"
    t.string "region"
    t.string "workspace_logo_filename"
    t.index ["organization_id"], name: "index_workspaces_on_organization_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
<<<<<<< HEAD
=======
  add_foreign_key "agentic_coding_app_clone_jobs", "agentic_coding_apps", column: "app_id", on_delete: :nullify
  add_foreign_key "agentic_coding_app_clone_jobs", "agentic_coding_apps", column: "source_app_id", on_delete: :nullify
  add_foreign_key "agentic_coding_app_clone_jobs", "users"
  add_foreign_key "agentic_coding_app_clone_jobs", "workspaces", column: "source_workspace_id", on_delete: :nullify
  add_foreign_key "agentic_coding_app_clone_jobs", "workspaces", on_delete: :cascade
  add_foreign_key "agentic_coding_app_git_targets", "agentic_coding_apps", column: "app_id"
  add_foreign_key "agentic_coding_app_git_targets", "git_targets"
  add_foreign_key "agentic_coding_app_resources", "agentic_coding_apps"
  add_foreign_key "agentic_coding_app_secrets", "agentic_coding_apps"
  add_foreign_key "agentic_coding_app_users", "agentic_coding_apps", column: "app_id"
  add_foreign_key "agentic_coding_app_users", "users"
  add_foreign_key "agentic_coding_app_users", "users", column: "invited_by_id"
  add_foreign_key "agentic_coding_app_visitors", "agentic_coding_apps", column: "app_id"
  add_foreign_key "agentic_coding_app_visitors", "agentic_coding_deployments", column: "deployment_id", on_delete: :nullify
  add_foreign_key "agentic_coding_apps", "agentic_coding_apps", column: "source_app_id"
  add_foreign_key "agentic_coding_apps", "agentic_coding_templates", column: "template_id"
  add_foreign_key "agentic_coding_apps", "users"
  add_foreign_key "agentic_coding_apps", "workspaces"
  add_foreign_key "agentic_coding_deployments", "agentic_coding_apps"
  add_foreign_key "agentic_coding_deployments", "agentic_coding_sessions"
  add_foreign_key "agentic_coding_deployments", "users", column: "version_author_id"
  add_foreign_key "agentic_coding_deployments", "workspaces"
  add_foreign_key "agentic_coding_prompts", "agentic_coding_apps"
  add_foreign_key "agentic_coding_prompts", "agentic_coding_sessions"
  add_foreign_key "agentic_coding_security_findings", "agentic_coding_apps"
  add_foreign_key "agentic_coding_security_findings", "agentic_coding_prompts", column: "resolving_prompt_id"
  add_foreign_key "agentic_coding_security_findings", "agentic_coding_security_scans", column: "first_detected_scan_id"
  add_foreign_key "agentic_coding_security_findings", "agentic_coding_security_scans", column: "last_detected_scan_id"
  add_foreign_key "agentic_coding_security_findings", "users", column: "ignored_by_user_id"
  add_foreign_key "agentic_coding_security_scans", "agentic_coding_apps"
  add_foreign_key "agentic_coding_security_scans", "agentic_coding_deployments", column: "deployment_id"
  add_foreign_key "agentic_coding_security_scans", "agentic_coding_sessions"
  add_foreign_key "agentic_coding_security_scans", "users", column: "triggered_by_user_id"
  add_foreign_key "agentic_coding_security_scans", "workspaces"
  add_foreign_key "agentic_coding_sessions", "agentic_coding_apps"
  add_foreign_key "agentic_coding_sessions", "users"
  add_foreign_key "agentic_coding_sessions", "workspaces"
  add_foreign_key "ahoy_events", "ahoy_visits", column: "visit_id"
>>>>>>> 662d24a7f (feat(CE): spending limit schema and models (#2237))
  add_foreign_key "alert_channels", "alert_media"
  add_foreign_key "alert_channels", "alerts"
  add_foreign_key "alerts", "workspaces"
  add_foreign_key "billing_subscriptions", "billing_plans", column: "plan_id"
  add_foreign_key "billing_subscriptions", "organizations"
  add_foreign_key "chat_messages", "data_app_sessions"
  add_foreign_key "chat_messages", "visual_components"
  add_foreign_key "chat_messages", "workspaces"
  add_foreign_key "components", "workflows", validate: false
  add_foreign_key "components", "workspaces", validate: false
  add_foreign_key "edges", "components", column: "source_component_id", validate: false
  add_foreign_key "edges", "components", column: "target_component_id", validate: false
  add_foreign_key "edges", "workflows", validate: false
  add_foreign_key "edges", "workspaces", validate: false
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "spending_limit_counters", "spending_limits", on_delete: :cascade
  add_foreign_key "spending_limits", "organizations"
  add_foreign_key "spending_limits", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "spending_limits", "workspaces"
  add_foreign_key "taggings", "tags"
  add_foreign_key "workflow_integrations", "workflows", validate: false
  add_foreign_key "workflow_integrations", "workspaces", validate: false
  add_foreign_key "workflow_runs", "workspaces"
  add_foreign_key "workflows", "workspaces", validate: false
  add_foreign_key "workspace_users", "roles"
  add_foreign_key "workspace_users", "users"
  add_foreign_key "workspace_users", "workspaces", on_delete: :nullify
  add_foreign_key "workspaces", "organizations"
end
