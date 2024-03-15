# frozen_string_literal: true

# spec/interactors/authentication/login_spec.rb

require "rails_helper"

RSpec.describe Authentication::Login, type: :interactor do
  subject(:context) { described_class.call(params:) }

  let(:user) { create(:user, password: "Password@123", password_confirmation: "Password@123") }

  describe ".call" do
    context "when given valid credentials" do
      let(:params) { { email: user.email, password: "Password@123" } }

      context "with a verified user" do
        before { user.update!(confirmed_at: Time.current) }

        it "succeeds" do
          expect(context).to be_success
        end

        it "provides a token" do
          expect(context.token).to be_present
        end
      end

      context "with an unverified user" do
        it "fails" do
          expect(context).to be_failure
        end

        it "provides an appropriate error message" do
          expect(context.error).to eq("Account not verified. Please verify your account.")
        end
      end
    end

    context "when given an invalid email" do
      let(:params) { { email: "not_found@example.com", password: "Password@123" } }

      it "fails" do
        expect(context).to be_failure
      end

      it "provides an error message" do
        expect(context.error).to eq("Invalid email or password")
      end
    end

    context "when given an invalid password" do
      let(:params) { { email: user.email, password: "wrong_password" } }

      it "fails" do
        expect(context).to be_failure
      end

      it "provides an error message" do
        expect(context.error).to eq("Invalid email or password")
      end
    end

    context "handling exceptions" do
      let(:params) { { email: user.email, password: "Password@123" } }

      it "handles unexpected errors gracefully" do
        allow(User).to receive(:find_by).and_raise(StandardError)
        expect { context }.not_to raise_error
        expect(context).to be_failure
      end
    end
  end
end
