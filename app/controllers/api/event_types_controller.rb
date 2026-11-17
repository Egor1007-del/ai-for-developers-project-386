class Api::EventTypesController < Api::BaseController
  rescue_from StandardError, with: :internal_error
  rescue_from ActionDispatch::Http::Parameters::ParseError, ActionController::BadRequest, with: :invalid_json

  def index
    render json: { data: EventType.order(:id).as_json(only: %i[id name description duration_minutes]) }
  rescue StandardError => error
    Rails.logger.error("Event types could not be loaded: #{error.full_message}")
    render json: { error: { code: "internal_error", message: "Не удалось загрузить типы событий" } },
           status: :internal_server_error
  end

  def create
    input = request.request_parameters
    event_type = EventType.new(input.slice("name", "description", "duration_minutes").select { |_, value| value.is_a?(String) || value.is_a?(Numeric) })
    event_type.valid?
    %w[name description].each do |field|
      event_type.errors.add(field, "должно быть строкой") unless input[field].nil? || input[field].is_a?(String)
    end
    unless [ 15, 30 ].include?(input["duration_minutes"]) && input["duration_minutes"].is_a?(Integer)
      event_type.errors.add(:duration_minutes, "выберите 15 или 30 минут")
    end
    if event_type.errors.empty? && event_type.save
      render json: event_type.as_json(only: %i[id name description duration_minutes]), status: :created
    else
      render json: { error: { code: "validation_error", message: "Проверьте поля формы", fields: event_type.errors.messages } },
             status: :unprocessable_entity
    end
  end

  def availability
    unless params[:id].match?(/\A[1-9]\d*\z/)
      return error("validation_error", "Некорректный ID типа события", :unprocessable_entity)
    end
    event_type = EventType.find_by(id: params[:id])
    return error("event_type_not_found", "Тип события не найден", :not_found) unless event_type

    render json: { time_zone: "Europe/Moscow", days: Availability.new(event_type).days }
  rescue StandardError => error
    raise unless database_unavailable?(error)

    service_unavailable
  end

  private

  def internal_error(error)
    Rails.logger.error("Event type could not be created: #{error.full_message}")
    render json: { error: { code: "internal_error", message: "Не удалось создать тип события" } }, status: :internal_server_error
  end
end
