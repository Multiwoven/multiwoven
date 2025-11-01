# frozen_string_literal: true

require "rails_helper"

RSpec.describe HostedDataStoreTable, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:column_count) }
    it { should validate_presence_of(:row_count) }
    it { should validate_presence_of(:size) }
    it { should validate_presence_of(:table_schema) }
  end

  describe "enum for sync_enabled" do
    it { should define_enum_for(:sync_enabled).with_values(%i[disabled enabled]) }
  end

  describe "associations" do
    it { should belong_to(:hosted_data_store) }
    it { should belong_to(:source_connector).class_name("Connector").optional }
    it { should belong_to(:destination_connector).class_name("Connector").optional }
  end
end
