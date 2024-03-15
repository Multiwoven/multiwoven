# frozen_string_literal: true

# spec/interactors/authentication/signup_spec.rb

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

      it "confirms the user" do
        expect(User.find_by(email: params[:email])).to be_nil

        # Execute the interactor
        context

        user = User.find_by(email: params[:email])
        expect(user).not_to be_nil
        expect(user.confirmed_at).not_to be_nil
      end

      it "provides a JWT token" do
        expect(context.token).not_to be_nil
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

      it "provides error messages related to missing company_name" do
        expect(context.user.errors[:company_name]).to include("can't be blank")
      end
    end

    context "when provided with invalid user attributes" do
      context "password and password_confirmation do not match" do
        let(:params) do
          {
            name: "User",
            email: "user@example.com",
            password: "Password@123",
            password_confirmation: "wrong_password"
          }
        end

        it "fails" do
          expect(context).to be_failure
        end

        it "provides error messages" do
          expect(context.user.errors[:password_confirmation]).to include("doesn't match Password")
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
          expect(context.user.errors[:email]).to include("can't be blank")
        end
      end

      context "name is missing" do
        let(:params) do
          {
            name: "",
            email: "user@example.com",
            password: "Password@123",
            password_confirmation: "Password@123"
          }
        end

        it "fails" do
          expect(context).to be_failure
        end

        it "provides error messages" do
          expect(context.user.errors[:name]).to include("can't be blank")
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

        it "fails" do
          expect(context).to be_failure
        end

        it "does not create a new user" do
          expect { context }.not_to change(User, :count)
        end

        it "provides error messages related to company name" do
          expect(context.user.errors[:company_name]).to include("has already been taken")
        end
      end
    end
  end
end
