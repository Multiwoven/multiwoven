# frozen_string_literal: true

# app/interactors/authentication/login.rb
module Authentication
  class Login
    include Interactor

    def call
      user = User.find_by(email: context.params[:email])

      context.fail!(error: "Invalid email or password") unless user&.valid_password?(context.params[:password])

      token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      user.update!(jti: payload["jti"])

      context.token = token
    end
  end
end
