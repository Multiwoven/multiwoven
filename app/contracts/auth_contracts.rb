# frozen_string_literal: true

module AuthContracts
  class Login < Dry::Validation::Contract
    params do
      required(:email).filled(:string)
      required(:password).filled(:string)
    end

    rule(:email) do
      key.failure("has invalid email format") unless /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i.match?(value)
    end
  end

  class Signup < Dry::Validation::Contract
    params do
      required(:name).filled(:string)
      required(:email).filled(:string)
      required(:password).filled(:string)
      required(:password_confirmation).filled(:string)
      required(:company_name).filled(:string)
    end

    rule(:email) do
      key.failure("has invalid email format") unless /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i.match?(value)
    end

    rule(:password, :password_confirmation) do
      key.failure("password doesn't match") if values[:password] != values[:password_confirmation]
    end
  end

  class Logout < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
    end
  end

  class ForgotPassword < Dry::Validation::Contract
    params do
      required(:email).filled(:string)
    end

    rule(:email) do
      key.failure("has invalid email format") unless /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i.match?(value)
    end
  end

  class ResetPassword < Dry::Validation::Contract
    params do
      required(:password).filled(:string)
      required(:password_confirmation).filled(:string)
      required(:reset_password_token).filled(:string)
    end

    rule(:password, :password_confirmation) do
      key.failure("password doesn't match") if values[:password] != values[:password_confirmation]
    end
  end

  class VerifyCode < Dry::Validation::Contract
    params do
      required(:email).filled(:string)
      required(:confirmation_code).filled(:string)
    end

    rule(:email) do
      key.failure("has invalid email format") unless /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i.match?(value)
    end
  end

  class ResendVerification < Dry::Validation::Contract
    params do
      required(:email).filled(:string)
    end

    rule(:email) do
      key.failure("has invalid email format") unless /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i.match?(value)
    end
  end
end
