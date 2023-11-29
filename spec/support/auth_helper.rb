# frozen_string_literal: true

# spec/support/auth_helper.rb
module AuthHelper
  def auth_headers(user)
    context = Authentication::Login.call(params: { email: user.email, password: user.password })
    token = context.token
    { "Authorization" => "Bearer #{token}" }
  end
end
