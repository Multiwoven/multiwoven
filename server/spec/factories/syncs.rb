# frozen_string_literal: true

# == Schema Information
#
# Table name: syncs
#
#  id                :bigint           not null, primary key
#  workspace_id      :integer
#  source_id         :integer
#  model_id          :integer
#  destination_id    :integer
#  configuration     :jsonb
#  source_catalog_id :integer
#  schedule_type     :integer
#  schedule_data     :jsonb
#  status            :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :sync do
    association :workspace
    association :model
    association :source, factory: :connector
    association :destination, factory: :connector
    configuration { { test: "Test" } }
    schedule_type { 1 }
    sync_interval { 1 }
    stream_name { "profile" }
    sync_interval_unit { "hours" }
    status { 1 }
  end
end
