# frozen_string_literal: true

class AuthenticationService
  def initialize(params)
    @params = params
  end

  def login
    user = User.find_by(email: @params[:email])
    return unless user&.valid_password?(@params[:password])

    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.update!(jti: payload["jti"])
    token
  end

  def signup
    user = User.new(email: @params[:email], password: @params[:password],
                    password_confirmation: @params[:password_confirmation])
    user.confirmation_code = generate_confirmation_code

    if user.save
      { success: true, message: "Signup successful!" }
    else
      { success: false, errors: user.errors.full_messages }
    end
  end

  def logout(current_user)
    User.revoke_jwt(nil, current_user)
    { success: true, message: "Successfully logged out" }
  rescue StandardError => e
    { success: false, errors: e.message }
  end

  private

  def generate_confirmation_code
    rand(100_000..999_999).to_s
  end
end
