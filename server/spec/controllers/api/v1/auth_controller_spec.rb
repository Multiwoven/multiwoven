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
  let(:user) { create(:user, :verified) }

  describe "POST #signup" do
    context "with valid parameters" do
      it "creates a new user and returns the user's data" do
        post :signup, params: user_attributes

        expect(response).to have_http_status(:created)
        expect(response_data["type"]).to eq("token")
        expect(response_data["attributes"]["token"]).not_to be_nil
      end
    end

    context "with invalid parameters" do
      it "does not create a user and returns an error" do
        post :signup, params: { email: "test", password: "pass", password_confirmation: "wrong" }

        expect(response).to have_http_status(:bad_request)
        expect(response_errors).not_to be_empty
      end
    end
  end

  describe "POST #login" do
    context "with valid parameters" do
      it "logs in a user and returns a token" do
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

  describe "POST #verify_code" do
    let(:user_with_code) { create(:user, confirmation_code: "123456") }

    context "with valid confirmation code" do
      it "verifies the user and returns a success message" do
        post :verify_code, params: { email: user_with_code.email, confirmation_code: user_with_code.confirmation_code }

        expect(response).to have_http_status(:ok)
        expect(response_data["attributes"]["message"]).to eq("Account verified successfully!")
      end
    end

    context "with invalid confirmation code" do
      it "does not verify the user and returns an error" do
        post :verify_code, params: { email: user_with_code.email, confirmation_code: "wrong" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_errors).not_to be_empty
      end
    end

    context "with no parameters" do
      it "returns a bad request status with an error message" do
        post :verify_code

        expect(response).to have_http_status(:bad_request)
        expect(response_errors).not_to be_empty
      end
    end
  end

  describe "POST #resend_verification" do
    let(:unverified_user) { create(:user) } # Assuming this creates an unverified user

    context "resending verification code" do
      it "sends a new verification code" do
        post :resend_verification, params: { email: unverified_user.email }

        expect(response).to have_http_status(:ok)
        expect(response_data["attributes"]["message"]).to eq("Verification code resent successfully.")
      end
    end

    context "with non-existent user" do
      it "returns an error" do
        post :resend_verification, params: { email: "nonexistent@example.com" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_errors).not_to be_empty
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
        request.headers.merge!(auth_headers(user, 0))
        delete :logout
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
