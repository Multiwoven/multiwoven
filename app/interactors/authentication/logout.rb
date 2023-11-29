# frozen_string_literal: true

# app/interactors/authentication/logout.rb
module Authentication
  class Logout
    include Interactor

    def call
      current_user = context.current_user
      User.revoke_jwt(nil, current_user)
      context.message = "Successfully logged out"
    rescue StandardError => e
      context.fail!(errors: e.message)
    end
  end
end
