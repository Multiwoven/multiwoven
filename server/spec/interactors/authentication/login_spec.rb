# frozen_string_literal: true

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

      context "with an unverified user with email verification disabled" do
        before do
          ENV["USER_EMAIL_VERIFICATION"] = "false"
        end

        it "succeeds" do
          expect(context).to be_success
        end

        it "provides a token" do
          expect(context.token).to be_present
        end
      end
    end

    context "when given an invalid email" do
      let(:params) { { email: "not_found@example.com", password: "Password@123" } }

      it "fails" do
        expect(context).to be_failure
      end

      it "provides an error message" do
        expect(context.error).to eq("Invalid login credentials, please try again")
      end
    end

    context "when given an invalid password" do
      let(:params) { { email: user.email, password: "wrong_password" } }

      it "fails" do
        expect(context).to be_failure
      end

      it "provides an error message" do
        expect(context.error).to eq("Invalid login credentials, please try again")
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

    context "with app_context" do
      let(:params) { { email: user.email, password: "Password@123" } }
      let(:app_context) { "embed" }

      before { user.update!(confirmed_at: Time.current) }

      context "when app_context is provided" do
        subject(:context) { described_class.call(params:, app_context:) }

        it "succeeds" do
          expect(context).to be_success
        end

        it "provides a token" do
          expect(context.token).to be_present
        end

        it "includes app_context in the token payload" do
          token = context.token
          secret = Devise::JWT.config.secret
          decoded = JWT.decode(token, secret, true, algorithm: "HS256")
          expect(decoded[0]["app_context"]).to eq("embed")
        end

        it "preserves standard JWT claims" do
          token = context.token
          secret = Devise::JWT.config.secret
          decoded = JWT.decode(token, secret, true, algorithm: "HS256")
          payload = decoded[0]
          expect(payload["sub"]).to be_present
          expect(payload["scp"]).to be_present
          expect(payload["jti"]).to be_present
          expect(payload["exp"]).to be_present
        end
      end

      context "when app_context is not provided" do
        subject(:context) { described_class.call(params:) }

        it "succeeds" do
          expect(context).to be_success
        end

        it "provides a token" do
          expect(context.token).to be_present
        end

        it "does not include app_context in the token payload" do
          token = context.token
          secret = Devise::JWT.config.secret
          decoded = JWT.decode(token, secret, true, algorithm: "HS256")
          expect(decoded[0]["app_context"]).to be_nil
        end
      end

      context "when app_context is empty string" do
        subject(:context) { described_class.call(params:, app_context: "") }

        it "succeeds" do
          expect(context).to be_success
        end

        it "does not include app_context in the token payload" do
          token = context.token
          secret = Devise::JWT.config.secret
          decoded = JWT.decode(token, secret, true, algorithm: "HS256")
          expect(decoded[0]["app_context"]).to be_nil
        end
      end
    end
  end
end
