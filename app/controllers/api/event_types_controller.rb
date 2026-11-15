class Api::EventTypesController < ApplicationController
  def index
    render json: { data: EventType.order(:id).as_json(only: %i[id name description duration_minutes]) }
  rescue StandardError => error
    Rails.logger.error("Event types could not be loaded: #{error.full_message}")
    render json: { error: { code: "internal_error", message: "Не удалось загрузить типы событий" } },
           status: :internal_server_error
  end
end
