class Api::BaseController < ApplicationController
  wrap_parameters false
  rescue_from ActionDispatch::Http::Parameters::ParseError, ActionController::BadRequest, with: :invalid_json

  private

  def error(code, message, status)
    render json: { error: { code: code, message: message } }, status: status
  end

  def invalid_json(_exception)
    error("invalid_json", "Некорректный JSON", :bad_request)
  end

  def database_unavailable?(exception)
    while exception
      return true if exception.is_a?(SQLite3::BusyException) || exception.is_a?(SQLite3::LockedException) ||
        exception.is_a?(ActiveRecord::ConnectionNotEstablished) || exception.is_a?(PG::ConnectionBad) ||
        exception.is_a?(PG::LockNotAvailable)
      exception = exception.cause
    end
    false
  end

  def service_unavailable
    error("service_unavailable", "Сервис временно недоступен. Попробуйте ещё раз.", :service_unavailable)
  end
end
