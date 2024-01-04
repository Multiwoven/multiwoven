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

ActiveRecord::Schema[7.1].define(version: 2024_01_03_195046) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "catalogs", force: :cascade do |t|
    t.integer "workspace_id"
    t.integer "connector_id"
    t.jsonb "catalog"
    t.string "catalog_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "syncs", force: :cascade do |t|
    t.integer "workspace_id"
    t.integer "source_id"
    t.integer "model_id"
    t.integer "destination_id"
    t.jsonb "configuration"
    t.integer "source_catalog_id"
    t.integer "schedule_type"
    t.jsonb "schedule_data"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workspace_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "workspace_id"
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["name"], name: "index_workspaces_on_name", unique: true
    t.index ["slug"], name: "index_workspaces_on_slug", unique: true
  end

  add_foreign_key "workspace_users", "users"
  add_foreign_key "workspace_users", "workspaces", on_delete: :nullify
end
