# frozen_string_literal: true

module Authentication
  class Signup
    include Interactor

    def call
      create_new_user
      assign_confirmation_code
      save_user
      send_confirmation_email
    end

    private

    attr_accessor :user

    def create_new_user
      self.user = User.new(
        name: context.params[:name],
        email: context.params[:email],
        password: context.params[:password],
        password_confirmation: context.params[:password_confirmation]
      )
    end

    def assign_confirmation_code
      user.confirmation_code = generate_confirmation_code
    end

    def save_user
      if user.save
        context.message = "Signup successful!"
      else
        context.fail!(errors: user.errors.full_messages)
      end
    end

    def send_confirmation_email
      UserMailer.send_confirmation_code(user).deliver_now
    end

    def generate_confirmation_code
      rand(100_000..999_999).to_s
    end
  end
end
