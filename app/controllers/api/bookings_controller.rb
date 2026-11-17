class Api::BookingsController < Api::BaseController
  rescue_from StandardError, with: :handle_error
  rescue_from ActionDispatch::Http::Parameters::ParseError, ActionController::BadRequest, with: :invalid_json

  def upcoming
    bookings = Booking.includes(:event_type).where("starts_at > ?", Time.current).order(:starts_at)
    render json: { data: bookings.map { |booking|
      { id: booking.id, event_type: booking.event_type.as_json(only: %i[id name description duration_minutes]),
        starts_at: booking.starts_at.in_time_zone(Availability::ZONE).iso8601,
        ends_at: booking.ends_at.in_time_zone(Availability::ZONE).iso8601 }
    } }
  end

  def create
    input = request.request_parameters
    unless input["event_type_id"].is_a?(Integer) && input["event_type_id"].positive? && input["starts_at"].is_a?(String) && input["starts_at"].present?
      return error("validation_error", "Укажите тип события и время начала", :unprocessable_entity)
    end
    event_type = EventType.find_by(id: input["event_type_id"])
    return error("event_type_not_found", "Тип события не найден", :not_found) unless event_type

    begin
      raise ArgumentError unless input["starts_at"].match?(/T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\z/)
      starts_at = Time.iso8601(input["starts_at"]).in_time_zone(Availability::ZONE)
    rescue ArgumentError
      return error("invalid_start_time", "Некорректное время начала", :unprocessable_entity)
    end
    availability = Availability.new(event_type)
    return error("invalid_start_time", "Выберите доступное время", :unprocessable_entity) unless availability.valid_start?(starts_at)

    ends_at = availability.ends_at_for(starts_at)
    booking = Booking.create!(event_type: event_type, starts_at: starts_at, ends_at: ends_at)
    render json: { id: booking.id, event_type: event_type.as_json(only: %i[id name description duration_minutes]),
                   starts_at: starts_at.iso8601, ends_at: ends_at.iso8601 }, status: :created
  end

  private

  def handle_error(exception)
    cause = exception
    causes = []
    while cause
      causes << cause
      cause = cause.cause
    end
    if causes.any? { |item| booking_conflict?(item) }
      error("booking_conflict", "Это время уже занято. Выберите другой слот.", :conflict)
    elsif database_unavailable?(exception)
      service_unavailable
    else
      Rails.logger.error("Booking failed: #{exception.full_message}")
      message = action_name == "upcoming" ? "Не удалось загрузить предстоящие записи" : "Не удалось создать запись"
      error("internal_error", message, :internal_server_error)
    end
  end

  def booking_conflict?(exception)
    return true if exception.is_a?(SQLite3::ConstraintException) && exception.message == "booking_conflict"

    exception.is_a?(PG::ExclusionViolation) &&
      exception.result&.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME) == "booking_no_overlap"
  end
end
