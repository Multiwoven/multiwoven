# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  # Test for Devise modules
  describe User, type: :model do
    it { should devise(:database_authenticatable) }
    it { should devise(:registerable) }
    it { should devise(:recoverable) }
    it { should devise(:rememberable) }
    it { should devise(:validatable) }
    it { should devise(:jwt_authenticatable) }
  end

  # Test for validations
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    # Add other validation tests here
  end

  # Test for associations
  describe "associations" do
    it { should have_many(:workspace_users).dependent(:nullify) }
    it { should have_many(:workspaces).through(:workspace_users) }
    # Add other association tests here
  end

  # Test for JWT methods
  describe "JWT revocation" do
    let(:user) { create(:user, jti: "test_jti") }
    let(:payload) { { "jti" => "test_jti" } }

    context "jwt_revoked?" do
      it "returns false if jti matches" do
        expect(User.jwt_revoked?(payload, user)).to be_falsey
      end

      it "returns true if jti does not match" do
        user.update!(jti: "new_jti")
        expect(User.jwt_revoked?(payload, user)).to be_truthy
      end
    end

    context "revoke_jwt" do
      it "sets the jti to nil" do
        User.revoke_jwt(nil, user)
        expect(user.reload.jti).to be_nil
      end
    end
  end

  # Additional tests for any other custom methods in User model
end
