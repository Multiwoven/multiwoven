# frozen_string_literal: true

FactoryBot.define do
  factory :tool, class: "Agents::Tool" do
    workspace
    sequence(:name) { |n| "MCP Tool #{n}" }
    label { "Test MCP Tool" }
    description { "A test MCP tool for connecting to external services" }
    tool_type { :mcp }
    enabled { true }
    configuration do
      {
        "url" => "https://mcp.example.com/sse",
        "transport" => "sse",
        "auth_type" => "bearer",
        "auth_config" => {
          "secret" => "test_secret_token"
        },
        "headers" => {},
        "timeout" => 30
      }
    end
    metadata { {} }

    trait :with_api_key_auth do
      configuration do
        {
          "url" => "https://mcp.example.com/api",
          "transport" => "http",
          "auth_type" => "api_key",
          "auth_config" => {
            "secret" => "test_api_key",
            "header_name" => "X-API-Key"
          },
          "headers" => {},
          "timeout" => 30
        }
      end
    end

    trait :with_basic_auth do
      configuration do
        {
          "url" => "https://mcp.example.com/api",
          "transport" => "http",
          "auth_type" => "basic",
          "auth_config" => {
            "username" => "test_user",
            "password" => "test_password"
          },
          "headers" => {},
          "timeout" => 30
        }
      end
    end

    trait :with_no_auth do
      configuration do
        {
          "url" => "https://mcp.example.com/api",
          "transport" => "http",
          "auth_type" => "none",
          "auth_config" => {},
          "headers" => {},
          "timeout" => 30
        }
      end
    end

    trait :with_custom_headers do
      configuration do
        {
          "url" => "https://mcp.example.com/sse",
          "transport" => "sse",
          "auth_type" => "bearer",
          "auth_config" => {
            "secret" => "test_secret_token"
          },
          "headers" => {
            "X-Custom-Header" => "custom_value",
            "X-Request-ID" => "12345"
          },
          "timeout" => 60
        }
      end
    end

    trait :disabled do
      enabled { false }
    end

    trait :slack do
      name { "Slack MCP" }
      label { "Slack" }
      description { "Slack MCP server for messaging" }
      configuration do
        {
          "url" => "https://mcp.slack.com/sse",
          "transport" => "sse",
          "auth_type" => "bearer",
          "auth_config" => {
            "secret" => "xoxb-test-token"
          }
        }
      end
      metadata do
        {
          "icon" => "https://res.cloudinary.com/dspflukeu/image/upload/v1/integrations/slack.svg",
          "category" => "team_collaboration"
        }
      end
    end

    trait :github do
      name { "GitHub MCP" }
      label { "GitHub" }
      description { "GitHub MCP server for repository operations" }
      configuration do
        {
          "url" => "https://mcp.run/dylibso/github",
          "transport" => "http",
          "auth_type" => "bearer",
          "auth_config" => {
            "secret" => "ghp_test_token"
          }
        }
      end
      metadata do
        {
          "icon" => "https://res.cloudinary.com/dspflukeu/image/upload/v1/integrations/github.svg",
          "category" => "developer_tools"
        }
      end
    end
  end
end
