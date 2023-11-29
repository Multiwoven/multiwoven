# frozen_string_literal: true

# spec/interactors/authentication/login_spec.rb

require "rails_helper"

RSpec.describe Authentication::Login, type: :interactor do
  subject(:context) { described_class.call(params:) }

  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  describe ".call" do
    context "when given valid credentials" do
      let(:params) { { email: user.email, password: "password" } }

      it "succeeds" do
        expect(context).to be_success
      end

      it "provides a token" do
        expect(context.token).to be_present
      end
    end

    context "when given an invalid email" do
      let(:params) { { email: "not_found@example.com", password: "password" } }

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
  end
end
