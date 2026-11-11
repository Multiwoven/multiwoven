# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utils::JwtSecret do
  describe ".fetch" do
    let(:production) { ActiveSupport::EnvironmentInquirer.new("production") }
    let(:development) { ActiveSupport::EnvironmentInquirer.new("development") }

    it "returns JWT_SECRET when it is set" do
      expect(described_class.fetch(env: { "JWT_SECRET" => "configured-secret" }, rails_env: production))
        .to eq("configured-secret")
    end

    it "raises in production when JWT_SECRET is missing" do
      expect { described_class.fetch(env: {}, rails_env: production) }
        .to raise_error(Utils::JwtSecret::MissingError, /JWT_SECRET/)
    end

    it "raises in production when JWT_SECRET is blank" do
      expect { described_class.fetch(env: { "JWT_SECRET" => " " }, rails_env: production) }
        .to raise_error(Utils::JwtSecret::MissingError)
    end

    it "falls back to secret_key_base outside production" do
      expect(described_class.fetch(env: {}, rails_env: development)).to eq(Rails.application.secret_key_base)
    end
  end

  it "signs user tokens with the resolved secret" do
    expect(Devise::JWT.config.secret).to eq(described_class.fetch)
  end
end
