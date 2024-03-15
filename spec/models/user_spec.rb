# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  jti                    :string
#  confirmation_code      :string
#  confirmed_at           :datetime
#  name                   :string
#
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
    it { should allow_value("user@example.com").for(:email) }
    it { should_not allow_value("user@example").for(:email) }
    it { should_not allow_value("user@").for(:email) }
    it { should_not allow_value("user").for(:email) }
    it { should validate_presence_of(:password) }
    it {
      should validate_length_of(:password)
        .is_at_least(Devise.password_length.min)
        .is_at_most(Devise.password_length.max)
    }
    it { should validate_uniqueness_of(:email).case_insensitive }
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

  describe "#verified?" do
    it "returns true if confirmed_at is set" do
      user = build(:user, confirmed_at: Time.current)
      expect(user.verified?).to be true
    end

    it "returns false if confirmed_at is nil" do
      user = build(:user, confirmed_at: nil)
      expect(user.verified?).to be false
    end
  end

  describe "password complexity" do
    it "is invalid if the password does not meet complexity requirements" do
      user = User.new(password: "password", email: "test@example.com", name: "Test User")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include(
        "Length should be 8-128 characters and include: 1 uppercase,lowercase,digit and special character"
      )
    end

    it "is valid if the password meets complexity requirements" do
      user = User.new(password: "Test123!", email: "test@example.com", name: "Test User")
      expect(user).to be_valid
    end
  end

  describe "invalid password lock" do
    before do
      @user = User.create!(
        email: "lock@example.com",
        password: "ValidPassword1!",
        name: "Lock Test User"
      )
    end

    it "locks the user after 5 failed attempts" do
      expect(@user.access_locked?).to be_falsey
      5.times do
        @user.valid_for_authentication? do
          false
        end
      end

      expect(@user.access_locked?).to be_truthy
    end
  end
end
