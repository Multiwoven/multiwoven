# frozen_string_literal: true

require "rails_helper"

RSpec.describe Authentication::Signup, type: :interactor do
  subject(:context) { described_class.call(params:) }

  describe ".call" do
    context "when provided with valid user attributes" do
      let(:params) do
        {
          name: "Test User",
          email: "user@example.com",
          password: "Password@123",
          password_confirmation: "Password@123",
          company_name: "Test Company"
        }
      end

      it "succeeds" do
        expect(context).to be_success
      end

      it "creates and does not confirm the user" do
        expect { context }.to change(User, :count).by(1)
        user = User.find_by(email: params[:email])
        expect(user).not_to be_nil
        expect(user.confirmed_at).to be_nil
      end

      it "creates a new user" do
        expect { context }.to change(User, :count).by(1)
      end

      it "creates a new organization" do
        expect { context }.to change(Organization, :count).by(1)
      end

      it "creates a new workspace" do
        expect { context }.to change(Workspace, :count).by(1)
      end

      it "creates a subscription for the organization" do
        create(:billing_plan, name: "Starter")
        expect { context }.to change(Billing::Subscription, :count).by(1)
        subscription = Billing::Subscription.last

        expect(subscription.organization).to eq(Organization.last)
        expect(subscription.plan.name).to eq("Starter")
        expect(subscription.status).to eq("active")
      end

      it "returns a success message" do
        expect(context.message).to eq("Signup successful! Please check your email to confirm your account.")
      end

      context "when email verification is disabled" do
        before do
          ENV["USER_EMAIL_VERIFICATION"] = "false"
        end

        it "does not send a confirmation email" do
          expect(User.email_verification_enabled?).to be false
        end
      end

      context "when email verification is enabled" do
        before do
          ENV["USER_EMAIL_VERIFICATION"] = "true"
        end

        it "send a confirmation email" do
          expect(User.email_verification_enabled?).to be true
        end
      end

      context "when email verification not set" do
        before do
          ENV["USER_EMAIL_VERIFICATION"] = nil
        end

        it "send a confirmation email" do
          expect(User.email_verification_enabled?).to be true
        end
      end
    end

    context "when company_name is not present" do
      let(:params) do
        {
          name: "Test User",
          email: "user@example.com",
          password: "Password@123",
          password_confirmation: "Password@123"
          # company_name is omitted
        }
      end

      it "fails" do
        expect(context).to be_failure
      end

      it "does not create a new user" do
        expect { context }.not_to change(User, :count)
      end

      it "does not create a new organization" do
        expect { context }.not_to change(Organization, :count)
      end

      it "does not create a new workspace" do
        expect { context }.not_to change(Workspace, :count)
      end
    end

    context "when provided with invalid user attributes" do
      context "password and password_confirmation do not match" do
        let(:params) do
          {
            name: "User",
            email: "user@example.com",
            password: "Password@123",
            password_confirmation: "wrong_password",
            company_name: "Company"
          }
        end

        it "fails" do
          expect(context).to be_failure
        end

        it "provides error messages" do
          expect(context.errors).to eq("Signup failed: Password confirmation doesn't match Password")
        end
      end

      context "email is missing" do
        let(:params) do
          {
            name: "Test User",
            email: "",
            password: "Password@123",
            password_confirmation: "Password@123"
          }
        end

        it "fails" do
          expect(context).to be_failure
        end

        it "provides error messages" do
          expect(context.errors).to include("Signup failed: Email can't be blank, Email is invalid")
        end
      end

      context "when provided with an existing email address" do
        let!(:existing_user) { create(:user, email: "user@example.com") }
        let(:params) do
          {
            name: "User",
            email: "user@example.com",
            password: "Password@123",
            password_confirmation: "Password@123"
          }
        end

        it "fails" do
          expect(context).to be_failure
          expect(context.errors).to include("There's already an account with this email address. " \
            "Use a different email or Sign In with this address")
        end
      end

      context "when provided with an existing company name" do
        let!(:existing_organization) { create(:organization, name: "Existing Company") }
        let(:params) do
          {
            name: "Test User",
            email: "user@example.com",
            password: "Password@123",
            password_confirmation: "Password@123",
            company_name: "Existing Company"
          }
        end

        it "succeeds" do
          expect(context).to be_success
        end

        it "creates and does not confirm the user" do
          expect { context }.to change(User, :count).by(1)
          user = User.find_by(email: params[:email])
          expect(user).not_to be_nil
          expect(user.confirmed_at).to be_nil
        end

        it "creates a new user" do
          expect { context }.to change(User, :count).by(1)
        end

        it "creates a new organization" do
          expect { context }.to change(Organization, :count).by(1)
        end

        it "creates a new workspace" do
          expect { context }.to change(Workspace, :count).by(1)
        end

        it "returns a success message" do
          expect(context.message).to eq("Signup successful! Please check your email to confirm your account.")
        end
      end
    end
  end
end
