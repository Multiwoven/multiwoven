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
ActiveRecord::Schema[7.1].define(version: 2025_05_06_000950) do
=======
ActiveRecord::Schema[7.1].define(version: 2025_05_19_183855) do
>>>>>>> d39d9809 (chore(CE): Add count_culture for chat_messages and message_feedbacks (#1119))
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
    t.index ["data_app_session_id", "created_at"], name: "index_chat_messages_on_data_app_session_id_and_created_at"
    t.index ["data_app_session_id"], name: "index_chat_messages_on_data_app_session_id"
    t.index ["visual_component_id"], name: "index_chat_messages_on_visual_component_id"
    t.index ["workspace_id"], name: "index_chat_messages_on_workspace_id"
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
    t.integer "model_id", null: false
    t.integer "reaction"
    t.json "feedback_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "feedback_type", default: 0, null: false
    t.string "session_id"
    t.jsonb "additional_remarks"
  end

  create_table "message_feedbacks", force: :cascade do |t|
    t.integer "workspace_id", null: false
    t.integer "data_app_id", null: false
    t.integer "visual_component_id", null: false
    t.integer "model_id", null: false
    t.integer "reaction"
    t.string "feedback_content"
    t.integer "feedback_type", default: 0, null: false
    t.json "chatbot_interaction", null: false
    t.jsonb "additional_remarks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", precision: nil
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

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

  create_table "visual_components", force: :cascade do |t|
    t.integer "component_type", null: false
    t.string "name"
    t.integer "workspace_id", null: false
    t.integer "data_app_id", null: false
    t.integer "model_id", null: false
    t.jsonb "properties"
    t.jsonb "feedback_config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "session_count", default: 0
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
    t.index ["organization_id"], name: "index_workspaces_on_organization_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "alert_channels", "alert_media"
  add_foreign_key "alert_channels", "alerts"
  add_foreign_key "alerts", "workspaces"
  add_foreign_key "billing_subscriptions", "billing_plans", column: "plan_id"
  add_foreign_key "billing_subscriptions", "organizations"
  add_foreign_key "chat_messages", "data_app_sessions"
  add_foreign_key "chat_messages", "visual_components"
  add_foreign_key "chat_messages", "workspaces"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "taggings", "tags"
  add_foreign_key "workspace_users", "roles"
  add_foreign_key "workspace_users", "users"
  add_foreign_key "workspace_users", "workspaces", on_delete: :nullify
  add_foreign_key "workspaces", "organizations"
end
