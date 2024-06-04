# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Core::QueryBuilder do
  describe ".perform" do
    let(:table) { "users" }

    context "when action is insert" do
      let(:action) { "destination_insert" }
      let(:params) { { "email" => "user@example.com", "name" => "John Doe" } }
      let(:primary_key) { "" } # Not used in creation

      it "generates a correct INSERT SQL query" do
        query = described_class.perform(action, table, params, primary_key)
        expect(query).to eq("INSERT INTO users (email, name) VALUES ('user@example.com', 'John Doe');")
      end
    end

    context "when action is update" do
      let(:action) { "destination_update" }

      context "with valid primary key" do
        let(:primary_key) { "user_id" }
        let(:params) { { "user_id" => "1", "location" => "New York" } }

        it "generates a correct UPDATE SQL query excluding the primary key from SET clause" do
          query = described_class.perform(action, table, params, primary_key)
          expect(query).to eq("UPDATE users SET location = 'New York' WHERE user_id = '1';")
        end
      end

      context "with missing primary key in params" do
        let(:primary_key) { "user_id" }
        let(:params) { { "location" => "New York" } }

        it "returns an error message" do
          query = described_class.perform(action, table, params, primary_key)
          expect(query).to eq("Primary key 'user_id' not found in record.")
        end
      end
    end

    context "when action is invalid" do
      let(:action) { "delete" }
      let(:params) { {} }
      let(:primary_key) { "" } # Not used

      it "returns an invalid action specified message" do
        query = described_class.perform(action, table, params, primary_key)
        expect(query).to eq("Invalid action specified.")
      end
    end
  end
end
