# frozen_string_literal: true

# spec/interactors/authentication/logout_spec.rb

require "rails_helper"

RSpec.describe Authentication::Logout, type: :interactor do
  subject(:context) { described_class.call(current_user:) }

  let(:current_user) { create(:user) }

  before do
    allow(User).to receive(:revoke_jwt).and_return(true)
  end

  describe ".call" do
    context "when the revoke_jwt method succeeds" do
      it "succeeds" do
        expect(context).to be_success
      end

      it "provides a success message" do
        expect(context.message).to eq("Successfully logged out")
      end
    end

    context "when an exception is raised" do
      before do
        allow(User).to receive(:revoke_jwt).and_raise(StandardError, "Something went wrong")
      end

      it "fails" do
        expect(context).to be_failure
      end

      it "provides error messages" do
        expect(context.errors).to eq("Something went wrong")
      end
    end
  end
end
