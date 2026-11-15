class Availability
  ZONE = ActiveSupport::TimeZone["Europe/Moscow"]
  DAYS = 14
  OPENING_HOUR = 9
  CLOSING_HOUR = 18
  STEP = 15.minutes

  def initialize(event_type, now: Time.current)
    @event_type = event_type
    @now = now.in_time_zone(ZONE)
  end

  def days
    first = @now.to_date
    last = first + DAYS
    occupied = Booking.where("starts_at < ? AND ends_at > ?", ZONE.local(last.year, last.month, last.day), @now).pluck(:starts_at, :ends_at)
    DAYS.times.map do |offset|
      date = first + offset
      slots = []
      busy_slots = []
      ((CLOSING_HOUR - OPENING_HOUR) * 60 / STEP.in_minutes).to_i.times do |index|
        starts_at = ZONE.local(date.year, date.month, date.day, OPENING_HOUR) + index * STEP
        ends_at = ends_at_for(starts_at)
        next unless valid_start?(starts_at)
        slot = { starts_at: starts_at.iso8601, ends_at: ends_at.iso8601 }
        if occupied.any? { |start_time, end_time| start_time < ends_at && end_time > starts_at }
          busy_slots << slot
        else
          slots << slot
        end
      end
      { date: date.iso8601, slots: slots, busy_slots: busy_slots }
    end
  end

  def ends_at_for(starts_at)
    starts_at + @event_type.duration_minutes.minutes
  end

  def valid_start?(starts_at)
    starts_at = starts_at.in_time_zone(ZONE)
    starts_at > @now && (@now.to_date...@now.to_date + DAYS).cover?(starts_at.to_date) &&
      starts_at.hour >= OPENING_HOUR && ends_at_for(starts_at) <= starts_at.beginning_of_day + CLOSING_HOUR.hours &&
      starts_at.min % STEP.in_minutes == 0 && starts_at.sec == 0 && starts_at.subsec == 0
  end
end
