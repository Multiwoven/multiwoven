# frozen_string_literal: true

FactoryBot.define do
  factory :agentic_coding_app_resource, class: "AgenticCoding::AppResource" do
    association :agentic_coding_app, factory: :agentic_coding_app
    resource_type { "neon_database" }
    resource_id { "proj_#{SecureRandom.hex(6)}" }
    credentials do
      {
        database_url: "postgresql://user:pass@ep-main.us-east-1.aws.neon.tech/neondb",
        dev_database_url: "postgresql://user:pass@ep-dev.us-east-1.aws.neon.tech/neondb"
      }
    end
    metadata do
      {
        region: "aws-us-east-1",
        branch_id: "br_main_#{SecureRandom.hex(4)}",
        dev_branch_id: "br_dev_#{SecureRandom.hex(4)}",
        main_endpoint_id: "ep_main_#{SecureRandom.hex(4)}"
      }
    end
    status { "provisioned" }

    trait :neon_database do
      resource_type { "neon_database" }
      resource_id { "proj_#{SecureRandom.hex(6)}" }
      credentials do
        {
          database_url: "postgresql://user:pass@ep-main.us-east-1.aws.neon.tech/neondb",
          dev_database_url: "postgresql://user:pass@ep-dev.us-east-1.aws.neon.tech/neondb"
        }
      end
      metadata do
        {
          region: "aws-us-east-1",
          branch_id: "br_main_#{SecureRandom.hex(4)}",
          dev_branch_id: "br_dev_#{SecureRandom.hex(4)}",
          main_endpoint_id: "ep_main_#{SecureRandom.hex(4)}"
        }
      end
    end

    trait :s3_storage do
      resource_type { "s3_storage" }
      resource_id { "apps/#{SecureRandom.uuid}/" }
      credentials { { endpoint: "https://s3.amazonaws.com", access_key: "AKIA_TEST", secret_key: "secret_test", bucket: "appgen-uploads" } }
      metadata { { provider: "aws" } }
    end

    trait :provisioning do
      status { "provisioning" }
    end

    trait :failed do
      status { "failed" }
    end
  end
end
