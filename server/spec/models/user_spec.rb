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

    describe ".email_verification_enabled?" do
      it "returns true when USER_EMAIL_VERIFICATION is not set to false" do
        allow(ENV).to receive(:[]).with("USER_EMAIL_VERIFICATION").and_return(nil)
        expect(User.email_verification_enabled?).to be true
      end

      it "returns false when USER_EMAIL_VERIFICATION is set to false" do
        allow(ENV).to receive(:[]).with("USER_EMAIL_VERIFICATION").and_return("false")
        expect(User.email_verification_enabled?).to be false
      end
    end

    describe "devise modules" do
      it "includes :confirmable when email verification is enabled" do
        allow(User).to receive(:email_verification_enabled?).and_return(true)
        expect(User.devise_modules).to include(:confirmable)
      end

      # Skipping this test because we need to reload the User class to simulate
      # the scenario where email verification is disabled. This cannot be easily
      # done within the context of a single test without affecting other tests.
      xit "does not include :confirmable when email verification is disabled" do
        allow(User).to receive(:email_verification_enabled?).and_return(false)
        expect(User.devise_modules).not_to include(:confirmable)
      end
    end
  end

  # Test for validations
  describe "validations" do
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
    it { should have_many(:roles).through(:workspace_users) }
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

    it "is invalid if the password length does not meet complexity requirements" do
      user = User.new(password: "test", email: "test@example.com", name: "Test User")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include(
        "Length should be 8-128 characters and include: 1 uppercase,lowercase,digit and special character"
      )
      password = "Tg6$eYp9Z!q3rV8W&dC1xJs@uH4nF7bLmK2tPiO0vQ!f5AaXyR9M$wB8ZcQ7Ds1EkJ2Tx!" \
                 "Lo3iNvU6Pg#m9RdFs4ThWz8YhT$uI5Lq3WrXvNp7O@dZm2BcJf1CkV0Aa4EvR6Pi8"
      user = User.new(
        password:,
        email: "test@example.com",
        name: "Test User"
      )
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
  context "status enum" do
    it "defines the status enum with the correct values" do
      expect(User.statuses).to eq("active" => 0, "invited" => 1, "expired" => 2)
    end

    it "sets the default status to 'active'" do
      user = User.new
      expect(user).to be_active
    end

    it "allows setting status to 'invited'" do
      user = User.new(status: :invited)
      expect(user).to be_invited
    end

    it "allows setting status to 'expired'" do
      user = User.new(status: :expired)
      expect(user).to be_expired
    end
  end
end
