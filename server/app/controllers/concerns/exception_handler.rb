# frozen_string_literal: true

module ExceptionHandler
  extend ActiveSupport::Concern

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    render_not_found_error(e.message)
  rescue Pundit::NotAuthorizedError
    # TODO: Add logs
    render_unauthorized("You are not authorized to do this action")
  rescue ActionController::ParameterMissing => e
    render_could_not_create_error(e.message)
  rescue JSON::ParserError, ActionDispatch::Http::Parameters::ParseError => e
    Utils::ExceptionReporter.report(e)
    render_bad_request_error(e.message)
  rescue StandardError => e
    Utils::ExceptionReporter.report(e)
    render_bad_request_error(e.message)
  end

  def render_not_found_error(message)
    render json: { error: message }, status: :not_found
  end

  def render_could_not_create_error(message)
    render json: { error: message }, status: :unprocessable_content
  end

  def render_unauthorized(message)
    render_error(
      message:,
      status: :unauthorized
    )
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
