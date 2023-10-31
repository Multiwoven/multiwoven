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
  end

  def render_not_found_error(message)
    render json: { error: message }, status: :not_found
  end

  def render_could_not_create_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end
end
