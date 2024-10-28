# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::AuthController, type: :controller do
  # Helper method to parse JSON response
  def json_response
    JSON.parse(response.body)
  end

  def response_data
    json_response["data"]
  end

  def response_errors
    json_response["errors"]
  end

  let(:user_attributes) { attributes_for(:user) }
  let(:user) { create(:user) }

  describe "POST #signup" do
    context "with valid parameters" do
      it "creates a new user and returns the user's data" do
        post :signup, params: user_attributes

        expect(response).to have_http_status(:created)
        expect(response_data["type"]).to eq("users")
        expect(response_data["attributes"]["name"]).not_to be_nil
      end
    end

    context "with invalid parameters" do
      it "does not create a user and returns an error" do
        post :signup, params: { email: "test", password: "pass", password_confirmation: "wrong" }

        expect(response).to have_http_status(:bad_request)
        expect(response_errors).not_to be_empty
      end

      it "does not create a user and returns an error" do
        post :signup,
             params: { name: "test", company_name: "test", email: "test@gmail.com", password: "pass@1235",
                       password_confirmation: "pass@1235" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_errors[0]["detail"]).not_to be_empty
        expect(response_errors[0]["detail"]).to include("Signup failed: Password Length should be 8-128 characters")
      end
    end

    context "when email verification is disabled" do
      before do
        allow(User).to receive(:email_verification_enabled?).and_return(false)
      end

      it "creates a new user and returns email_verification_enabled as false" do
        post :signup, params: user_attributes
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:attributes][:email_verification_enabled]).to eq(false)
      end
    end

    context "when email verification is enabled" do
      before do
        allow(User).to receive(:email_verification_enabled?).and_return(true)
      end

      it "creates a new user and returns email_verification_enabled as true" do
        post :signup, params: user_attributes
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:attributes][:email_verification_enabled]).to eq(true)
      end
    end
  end

  describe "POST #login" do
    context "with valid parameters" do
      it "logs in a user and returns a token" do
        user.confirm
        post :login, params: { email: user.email, password: user.password }

        expect(response).to have_http_status(:ok)
        expect(response_data["attributes"]["token"]).not_to be_nil
      end
    end

    context "with invalid parameters" do
      it "does not log in a user and returns an error" do
        post :login, params: { email: "wrong", password: "wrong" }

        expect(response).to have_http_status(:bad_request)
        expect(response_errors).not_to be_nil
      end
    end
  end

  describe "POST #forgot_password" do
    context "with valid email" do
      it "sends reset password instructions and returns a success message" do
        post :forgot_password, params: { email: user.email }

        expect(response).to have_http_status(:ok)
        expect(response_data["attributes"]["message"]).to eq("Reset password instructions sent to email.")
      end
    end

    context "with invalid email" do
      it "does not send reset password instructions and returns an error" do
        post :forgot_password, params: { email: "nothing@123.com" }

        expect(response).to have_http_status(:not_found)
        expect(response_errors).not_to be_empty
      end
    end
  end

  describe "POST #reset_password" do
    context "with valid reset password token" do
      it "resets the password and returns a success message" do
        token = user.send_reset_password_instructions
        post :reset_password,
             params: { reset_password_token: token, password: "newPassword@123",
                       password_confirmation: "newPassword@123" }

        expect(response).to have_http_status(:ok)
        expect(response_data["attributes"]["message"]).to eq("Password successfully reset.")
      end
    end

    context "with reset password token and its expired" do
      it "fail the reset password and returns a token has expired" do
        Timecop.freeze(Time.zone.now)
        token = user.send_reset_password_instructions
        user.update(reset_password_sent_at: 6.hours.ago - 1.minute)

        post :reset_password,
             params: { reset_password_token: token, password: "newPassword@123",
                       password_confirmation: "newPassword@123" }

        expect(response).to have_http_status(:unprocessable_entity)
        response_json = JSON.parse(response.body)
        expect(response_json["errors"].first["detail"]).to eq("Token has expired.")
        Timecop.return
      end
    end

    context "with invalid reset password token" do
      it "does not reset the password and returns an error" do
        post :reset_password,
             params: { reset_password_token: "wrong", password: "newPassword@123",
                       password_confirmation: "newPassword@123" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_errors).not_to be_empty
      end
    end
  end

  describe "GET #verify_user" do
    context "with valid confirmation token" do
      let(:confirmation_token) { user.confirmation_token }

      it "verifies the user and returns a success message" do
        get :verify_user, params: { confirmation_token: }

        expect(response).to have_http_status(:ok)
        expect(response_data["attributes"]["message"]).to eq("Account verified successfully!")
      end
    end

    context "with invalid confirmation code" do
      it "does not verify the user and returns an error" do
        get :verify_user, params: { confirmation_token: "wrong123" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_errors).not_to be_empty
      end
    end

    context "with no parameters" do
      it "returns a bad request status with an error message" do
        get :verify_user

        expect(response).to have_http_status(:bad_request)
        expect(response_errors).not_to be_empty
      end
    end
  end

  describe "POST #resend_verification" do
    let(:unverified_user) { create(:user) } # Assuming this creates an unverified user

    context "resending verification email" do
      it "sends a new verification email" do
        post :resend_verification, params: { email: unverified_user.email }
        expect(response).to have_http_status(:ok)
        expect(response_data["attributes"]["message"]).to eq("Email verification link sent successfully!")
      end

      it "returns an error already confirmed" do
        unverified_user.confirm
        post :resend_verification, params: { email: unverified_user.email }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_errors[0]["detail"]).to include("Account already confirmed")
      end
    end

    context "with non-existent user" do
      it "returns an error" do
        post :resend_verification, params: { email: "nonexistent@example.com" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_errors).not_to be_empty
        expect(response_errors[0]["detail"]).to include("User not found")
      end
    end
  end

  describe "DELETE #logout" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        delete :logout
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and logout user" do
        user.confirm
        request.headers.merge!(auth_headers(user, 0))
        delete :logout
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
