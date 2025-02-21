# frozen_string_literal: true

require "rails_helper"

RSpec.describe Authentication::ResendVerificationEmail, type: :interactor do
  describe ".call" do
    let(:email) { "test@example.com" }
    let(:user) { create(:user, email:, confirmed_at: nil) }
    let(:context) { described_class.call(params: { email: }) }

    context "when user is found" do
      before do
        allow(User).to receive(:find_by).with(email:).and_return(user)
      end

      context "when user is not confirmed" do
        it "sends confirmation instructions" do
          expect(user).to receive(:send_confirmation_instructions)
          context
        end

        it "sets a success message" do
          expect(context.message).to eq("Please check your email to confirm your account.")
        end

        it "does not fail the context" do
          expect(context).not_to be_failure
        end
      end

      context "when user is already confirmed" do
        let(:user) { create(:user, email:, confirmed_at: Time.current) }

        it "does not send confirmation instructions" do
          expect(user).not_to receive(:send_confirmation_instructions)
          context
        end

        it "fails the context with an appropriate error" do
          expect(context).to be_failure
          expect(context.error).to eq("Account already confirmed.")
          expect(context.status).to eq(:unprocessable_content)
        end
      end
    end

    context "when user is not found" do
      before do
        allow(User).to receive(:find_by).with(email:).and_return(nil)
      end

      it "fails the context with an appropriate error" do
        expect(context).to be_failure
        expect(context.error).to eq("User not found.")
        expect(context.status).to eq(:not_found)
      end
    end
  end
end
