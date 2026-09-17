# frozen_string_literal: true

require "rails_helper"

describe EnterpriseRoleContracts do
  let(:valid_permissions) do
    {
      connector_definition: { create: true, read: true, update: true, delete: true },
      connector: { create: true, read: true, update: true, delete: true },
      model: { create: true, read: true, update: true, delete: true },
      report: { create: true, read: true, update: true, delete: true },
      sync_record: { create: true, read: true, update: true, delete: true },
      sync_run: { create: true, read: true, update: true, delete: true },
      sync: { create: true, read: true, update: true, delete: true },
      user: { create: true, read: true, update: true, delete: true },
      workspace: { create: true, read: true, update: true, delete: true },
      data_app: { create: true, read: true, update: true, delete: true },
      audit_logs: { create: true, read: true, update: true, delete: true },
      alerts: { create: true, read: true, update: true, delete: true },
      billing: { create: true, read: true, update: true, delete: true },
      hosted_datastore: { create: true, read: true, update: true, delete: true },
      spending_limit: { create: true, read: true, update: true, delete: true }
    }
  end

  describe "the spending limit permission" do
    let(:payload) do
      lambda do |spending_limit|
        permissions = valid_permissions.merge(spending_limit ? { spending_limit: } : {})
        { role: { role_name: "Admin", policies: { permissions: } } }
      end
    end

    it "is accepted when a client leaves it out, so an older client keeps working" do
      expect(EnterpriseRoleContracts::Create.new.call(payload.call(nil))).to be_success
    end

    it "is refused when it is not a hash of the four actions" do
      result = EnterpriseRoleContracts::Create.new.call(payload.call("granted"))

      expect(result).not_to be_success
      expect(result.errors.to_h.dig(:role, :policies, :permissions, :spending_limit)).to include("must be a hash")
    end

    it "is refused when an action is not a boolean at all" do
      result = EnterpriseRoleContracts::Update.new.call(
        payload.call({ create: "maybe", read: true, update: true, delete: true }).merge(id: 1)
      )

      expect(result).not_to be_success
    end
  end

  describe EnterpriseRoleContracts::Create do
    let(:contract) { described_class.new }
    let(:valid_input) do
      {
        role: {
          role_name: "Admin",
          policies: {
            permissions: valid_permissions
          }
        }
      }
    end

    it "validates a correct role creation payload" do
      result = contract.call(valid_input)
      expect(result).to be_success
    end

    it "fails when role_name is missing" do
      input = valid_input.dup
      input[:role].delete(:role_name)
      result = contract.call(input)
      expect(result).to be_failure
    end

    it "fails when permissions are missing" do
      input = valid_input.dup
      input[:role][:policies].delete(:permissions)
      result = contract.call(input)
      expect(result).to be_failure
    end

    it "fails when permissions structure is invalid" do
      input = valid_input.dup
      input[:role][:policies][:permissions] = "invalid_structure"
      result = contract.call(input)
      expect(result).to be_failure
    end
  end

  describe EnterpriseRoleContracts::Update do
    let(:contract) { described_class.new }
    let(:valid_input) do
      {
        id: 1,
        role: {
          role_name: "Admin",
          policies: {
            permissions: valid_permissions
          }
        }
      }
    end

    it "validates a correct update payload" do
      result = contract.call(valid_input)
      expect(result).to be_success
    end

    it "fails when id is missing" do
      input = valid_input.dup
      input.delete(:id)
      result = contract.call(input)
      expect(result).to be_failure
    end

    it "updates only role_name" do
      input = valid_input.dup
      input[:role].delete(:policies)
      result = contract.call(input)
      expect(result).to be_success
    end

    it "updates only permissions" do
      input = valid_input.dup
      input[:role].delete(:role_name)
      result = contract.call(input)
      expect(result).to be_success
    end
  end

  describe EnterpriseRoleContracts::Destroy do
    let(:contract) { described_class.new }

    it "validates a correct destroy payload" do
      result = contract.call(id: 1)
      expect(result).to be_success
    end

    it "fails when id is missing" do
      result = contract.call({})
      expect(result).to be_failure
    end
  end
end
