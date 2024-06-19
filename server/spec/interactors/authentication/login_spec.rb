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

      it "increments the failed_attempts count" do
        expect { context }.to change { user.reload.failed_attempts }.by(1)
      end
    end

    context "when user exceeds max attempts" do
      let(:params) { { email: user.email, password: "wrong_password" } }

      before do
        user.update(failed_attempts: Devise.maximum_attempts - 1)
      end

      it "locks the user account" do
        context
        expect(context).to be_failure
        expect(context.error).to eq("Account is locked due to multiple login attempts. Please retry after sometime")
        expect(user.reload.access_locked?).to be(true)
      end
    end

    context "when user is locked and unlock period has passed" do
      let(:params) { { email: user.email, password: "Password@123" } }

      before do
        user.update(failed_attempts: Devise.maximum_attempts, locked_at: Time.current, confirmed_at: Time.current)
      end

      it "unlocks the user account after the unlock period" do
        travel_to 2.hours.from_now do
          context
          expect(context).to be_success
          expect(user.reload.access_locked?).to be(false)
          expect(context.token).to be_present
        end
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
