# frozen_string_literal: true

module EmbeddedContextRestriction
  extend ActiveSupport::Concern

  included do
    before_action :restrict_embedded_context_apis
  end

  private

  # Restrict APIs for embedded context tokens
  def restrict_embedded_context_apis
    return unless embedded_context_token?
    return if embedded_context_allowed?

    render_error(
      message: "This API endpoint is not available for embedded context tokens",
      status: :forbidden
    )
  end

  def embedded_context_token?
    @embedded_context_token ||= app_context_from_token == "embed"
  end

  def app_context_from_token
    return nil unless user_signed_in?

    token = extract_bearer_token
    return nil if token.blank?

    decode_token_and_extract_app_context(token)
  end

  def extract_bearer_token
    auth_header = request.headers["Authorization"]
    return nil unless auth_header&.start_with?("Bearer ")

    auth_header.split(" ").last
  end

  def decode_token_and_extract_app_context(token)
    secret = Devise::JWT.config.secret
    algorithm = Devise::JWT.config.algorithm || Warden::JWTAuth.config.algorithm
    decode_key = Devise::JWT.config.decoding_secret || secret

    decoded = JWT.decode(token, decode_key, true, algorithm:)
    decoded[0]["app_context"]
  rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError
    nil
  end

  def embedded_context_allowed?
    allowed_endpoints = embedded_context_allowed_endpoints
    current_controller = controller_path
    current_action = action_name.to_sym

    allowed_endpoints.any? do |endpoint|
      controller_match = endpoint[:controller]
      action_match = endpoint[:action]

      controller_matches = controller_match.nil? || current_controller == controller_match.to_s
      action_matches = action_match.nil? || current_action == action_match

      controller_matches && action_matches
    end
  end

  def embedded_context_allowed_endpoints
    [
      # UsersController - me action
      { controller: "api/v1/users", action: :me },
      # DataAppSessionsController - all APIs
      { controller: "enterprise/api/v1/data_app_sessions", action: nil },
      # DataAppsController - specific actions
      { controller: "enterprise/api/v1/data_apps", action: :index },
      { controller: "enterprise/api/v1/data_apps", action: :show },
      { controller: "enterprise/api/v1/data_apps", action: :fetch_data },
      { controller: "enterprise/api/v1/data_apps", action: :fetch_data_stream },
      { controller: "enterprise/api/v1/data_apps", action: :write_data },
      # WorkflowsController - specific actions
      { controller: "enterprise/api/v1/agents/workflows", action: :index },
      { controller: "enterprise/api/v1/agents/workflows", action: :show },
      { controller: "enterprise/api/v1/agents/workflows", action: :run },
      # MessageFeedbacksController - all APIs
      { controller: "enterprise/api/v1/message_feedbacks", action: nil },
      # FeedbacksController - all APIs
      { controller: "enterprise/api/v1/feedbacks", action: nil },
      # CustomVisualComponentController - show action
      { controller: "enterprise/api/v1/custom_visual_component", action: :show }
    ]
  end
end
