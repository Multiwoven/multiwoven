# frozen_string_literal: true

require "rails_helper"

RSpec.describe HostedDataStore, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:database_type) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:state) }
  end

  describe "enum for database_type" do
    it { should define_enum_for(:database_type).with_values(%i[vector_db raw_sql]) }
  end

  describe "enum for state" do
    it { should define_enum_for(:state).with_values(%i[disabled enabled]) }
  end

  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:source_connector).class_name("Connector").optional }
    it { should belong_to(:destination_connector).class_name("Connector").optional }
    it { should have_many(:hosted_data_store_tables).dependent(:destroy) }
  end
end
