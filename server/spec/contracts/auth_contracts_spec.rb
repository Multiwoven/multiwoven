# frozen_string_literal: true

require "rails_helper"

RSpec.describe "AuthContracts" do
  describe AuthContracts::Login do
    subject(:contract) { described_class.new }

    context "when valid inputs are provided" do
      let(:valid_inputs) { { email: "user@example.com", password: "password123" } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "when invalid email format is provided" do
      let(:invalid_inputs) { { email: "not_an_email", password: "password123" } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:email]).to include("has invalid email format")
      end
    end
  end

  describe AuthContracts::Signup do
    subject(:contract) { described_class.new }

    context "when valid inputs are provided" do
      let(:valid_inputs) do
        {
          name: "John Doe",
          email: "john@example.com",
          password: "password123",
          password_confirmation: "password123",
          company_name: "Example Corp"
        }
      end

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "when passwords do not match" do
      let(:invalid_inputs) do
        {
          name: "John Doe",
          email: "john@example.com",
          password: "password123",
          password_confirmation: "different123",
          company_name: "Example Corp"
        }
      end

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result).to_not be_success
      end
    end
  end

  describe AuthContracts::Logout do
    subject(:contract) { described_class.new }

    context "when id is provided and valid" do
      let(:valid_inputs) { { id: 1 } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "when id is provided but not an integer" do
      let(:invalid_inputs) { { id: "abc" } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result).to_not be_success
      end
    end
  end

  describe AuthContracts::ForgotPassword do
    subject(:contract) { described_class.new }

    context "when valid email is provided" do
      let(:valid_inputs) { { email: "user@example.com" } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "when invalid email format is provided" do
      let(:invalid_inputs) { { email: "not_an_email" } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:email]).to include("has invalid email format")
      end
    end
  end

  describe AuthContracts::ResetPassword do
    subject(:contract) { described_class.new }

    context "when valid inputs are provided" do
      let(:valid_inputs) do
        {
          password: "newpassword123",
          password_confirmation: "newpassword123",
          reset_password_token: "token123"
        }
      end

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "when passwords do not match" do
      let(:invalid_inputs) do
        {
          password: "newpassword123",
          password_confirmation: "differentpassword",
          reset_password_token: "token123"
        }
      end

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result).to_not be_success
      end
    end
  end

  describe AuthContracts::VerifyCode do
    subject(:contract) { described_class.new }

    context "when valid inputs are provided" do
      let(:valid_inputs) do
        {
          email: "user@example.com",
          confirmation_code: "code123"
        }
      end

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "when invalid email format is provided" do
      let(:invalid_inputs) { { email: "not_an_email", confirmation_code: "code123" } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:email]).to include("has invalid email format")
      end
    end
  end

  describe AuthContracts::ResendVerification do
    subject(:contract) { described_class.new }

    context "when valid email is provided" do
      let(:valid_inputs) { { email: "user@example.com" } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "when invalid email format is provided" do
      let(:invalid_inputs) { { email: "not_an_email" } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:email]).to include("has invalid email format")
      end
    end
  end
end
