# frozen_string_literal: true

# spec/interactors/authentication/signup_spec.rb

require "rails_helper"

RSpec.describe Authentication::Signup, type: :interactor do
  subject(:context) { described_class.call(params:) }

  describe ".call" do
    context "when provided with valid user attributes" do
      let(:params) do
        {
          name: "Test User",
          email: "user@example.com",
          password: "password",
          password_confirmation: "password"
        }
      end

      it "succeeds" do
        expect(context).to be_success
      end

      it "provides a success message" do
        expect(context.message).to eq("Signup successful!")
      end
    end

    context "when provided with invalid user attributes" do
      context "password and password_confirmation do not match" do
        let(:params) do
          {
            name: "User",
            email: "user@example.com",
            password: "password",
            password_confirmation: "wrong_password"
          }
        end

        it "fails" do
          expect(context).to be_failure
        end

        it "provides error messages" do
          expect(context.errors).to include("Password confirmation doesn't match Password")
        end
      end

      context "email is missing" do
        let(:params) do
          {
            name: "Test User",
            email: "",
            password: "password",
            password_confirmation: "password"
          }
        end

        it "fails" do
          expect(context).to be_failure
        end

        it "provides error messages" do
          expect(context.errors).to include("Email can't be blank")
        end
      end

      context "name is missing" do
        let(:params) do
          {
            name: "",
            email: "user@example.com",
            password: "password",
            password_confirmation: "password"
          }
        end

        it "fails" do
          expect(context).to be_failure
        end

        it "provides error messages" do
          expect(context.errors).to include("Name can't be blank")
        end
      end
    end
  end
end
