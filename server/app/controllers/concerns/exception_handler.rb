# frozen_string_literal: true

module ExceptionHandler
  extend ActiveSupport::Concern

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    # TODO: Add logs
    render_not_found_error(e.message)
  rescue ActionController::ParameterMissing => e
    # TODO: Add logs
    render_could_not_create_error(e.message)
  rescue JSON::ParserError, ActionDispatch::Http::Parameters::ParseError => e
    # TODO: Add logs
    render_bad_request_error(e.message)
  rescue StandardError => e
    render_bad_request_error(e.message)
  end

  def render_not_found_error(message)
    render json: { error: message }, status: :not_found
  end

  def render_could_not_create_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def render_bad_request_error(message)
    render json: {
      errors: [
        {
          status: 400,
          title: "Bad Request",
          detail: "There was a problem with the request format: #{message}",
          source: { pointer: "/request/payload" }
        }
      ]
    }, status: :bad_request
  end
end
