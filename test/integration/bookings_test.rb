require "test_helper"

class BookingsTest < ActionDispatch::IntegrationTest
  test "connection pool timeouts are reported as unavailable by booking and availability APIs" do
    event_type = EventType.create!(name: "Звонок", description: "Описание", duration_minutes: 15)
    original = Availability.method(:new)
    Availability.define_singleton_method(:new) { |*| raise ActiveRecord::ConnectionTimeoutError, "pool timeout" }
    travel_to Time.utc(2026, 11, 15, 6) do
      post "/api/bookings", params: { event_type_id: event_type.id, starts_at: "2026-11-15T10:00:00+03:00" }, as: :json
      assert_response :service_unavailable
      assert_equal "service_unavailable", response.parsed_body.dig("error", "code")
      get "/api/event_types/#{event_type.id}/availability"
      assert_response :service_unavailable
      assert_equal "service_unavailable", response.parsed_body.dig("error", "code")
    end
  ensure
    Availability.define_singleton_method(:new, original) if original
  end

  test "database connection errors are reported as unavailable" do
    event_type = EventType.create!(name: "Звонок", description: "Описание", duration_minutes: 15)
    original = Availability.method(:new)
    Availability.define_singleton_method(:new) { |*| raise PG::ConnectionBad, "booking_conflict connection failed" }
    travel_to Time.utc(2026, 11, 15, 6) do
      post "/api/bookings", params: { event_type_id: event_type.id, starts_at: "2026-11-15T10:00:00+03:00" }, as: :json
      assert_response :service_unavailable
      assert_equal "service_unavailable", response.parsed_body.dig("error", "code")
    end
  ensure
    Availability.define_singleton_method(:new, original) if original
  end

  test "unrelated database errors mentioning booking_conflict are not conflicts" do
    event_type = EventType.create!(name: "Звонок", description: "Описание", duration_minutes: 15)
    original = Availability.method(:new)
    Availability.define_singleton_method(:new) { |*| raise ActiveRecord::StatementInvalid, "booking_conflict database unavailable" }
    travel_to Time.utc(2026, 11, 15, 6) do
      post "/api/bookings", params: { event_type_id: event_type.id, starts_at: "2026-11-15T10:00:00+03:00" }, as: :json
      assert_response :internal_server_error
      assert_equal "internal_error", response.parsed_body.dig("error", "code")
    end
  ensure
    Availability.define_singleton_method(:new, original) if original
  end

  test "upcoming bookings returns an empty data array" do
    get "/api/bookings/upcoming"
    assert_response :success
    assert_equal({ "data" => [] }, response.parsed_body)
  end

  test "upcoming bookings include all event types in start order and exclude started bookings" do
    short = EventType.create!(name: "Короткий", description: "Первый", duration_minutes: 15)
    long = EventType.create!(name: "Длинный", description: "Второй", duration_minutes: 30)
    travel_to Time.utc(2026, 11, 15, 6) do
      Booking.create!(event_type: short, starts_at: Time.utc(2026, 11, 15, 5, 30), ends_at: Time.utc(2026, 11, 15, 5, 45))
      Booking.create!(event_type: short, starts_at: Time.current, ends_at: 15.minutes.from_now)
      later = Booking.create!(event_type: long, starts_at: 2.hours.from_now, ends_at: 2.hours.from_now + 30.minutes)
      earlier = Booking.create!(event_type: short, starts_at: 1.hour.from_now, ends_at: 1.hour.from_now + 15.minutes)

      get "/api/bookings/upcoming"
      assert_response :success
      assert_equal [
        { "id" => earlier.id, "event_type" => { "id" => short.id, "name" => "Короткий", "description" => "Первый", "duration_minutes" => 15 }, "starts_at" => "2026-11-15T10:00:00+03:00", "ends_at" => "2026-11-15T10:15:00+03:00" },
        { "id" => later.id, "event_type" => { "id" => long.id, "name" => "Длинный", "description" => "Второй", "duration_minutes" => 30 }, "starts_at" => "2026-11-15T11:00:00+03:00", "ends_at" => "2026-11-15T11:30:00+03:00" }
      ], response.parsed_body.fetch("data")
    end
  end
  test "availability reports SQLite busy and locked errors as service unavailable" do
    event_type = EventType.create!(name: "Звонок", description: "Описание", duration_minutes: 15)
    [ SQLite3::BusyException, SQLite3::LockedException ].each do |exception_class|
      failure = ->(*) do
        begin
          raise exception_class, "database locked"
        rescue exception_class
          raise ActiveRecord::StatementInvalid, "database error"
        end
      end
      original = Availability.method(:new)
      Availability.define_singleton_method(:new, &failure)
      begin
        get "/api/event_types/#{event_type.id}/availability"
      ensure
        Availability.define_singleton_method(:new, original)
      end
      assert_response :service_unavailable
      assert_equal "service_unavailable", response.parsed_body.dig("error", "code")
    end
  end

  test "creates a booking, rejects overlaps across types, and permits adjacent bookings" do
    short = EventType.create!(name: "Короткий", description: "Описание", duration_minutes: 15)
    long = EventType.create!(name: "Длинный", description: "Описание", duration_minutes: 30)
    travel_to Time.utc(2026, 11, 15, 6) do
      post "/api/bookings", params: { event_type_id: long.id, starts_at: "2026-11-15T10:00:00+03:00", ends_at: "2026-11-15T10:01:00+03:00" }, as: :json
      assert_response :created
      assert_equal "2026-11-15T10:30:00+03:00", response.parsed_body.fetch("ends_at")
      post "/api/bookings", params: { event_type_id: short.id, starts_at: "2026-11-15T10:15:00+03:00" }, as: :json
      assert_response :conflict
      assert_equal "booking_conflict", response.parsed_body.dig("error", "code")
      post "/api/bookings", params: { event_type_id: short.id, starts_at: "2026-11-15T10:30:00+03:00" }, as: :json
      assert_response :created
    end
  end
  test "rejects a different type contained in an existing hour-long booking" do
    existing_type = EventType.create!(name: "Существующий", description: "Описание", duration_minutes: 30)
    new_type = EventType.create!(name: "Новый", description: "Описание", duration_minutes: 30)
    travel_to Time.utc(2026, 11, 15, 6) do
      Booking.create!(event_type: existing_type, starts_at: Time.iso8601("2026-11-15T10:00:00+03:00"), ends_at: Time.iso8601("2026-11-15T11:00:00+03:00"))

      assert_no_difference "Booking.count" do
        post "/api/bookings", params: { event_type_id: new_type.id, starts_at: "2026-11-15T10:30:00+03:00" }, as: :json
        assert_response :conflict
        assert_equal "booking_conflict", response.parsed_body.dig("error", "code")
      end
    end
  end

  test "availability includes fourteen Moscow days and excludes past and late slots" do
    event_type = EventType.create!(name: "Звонок", description: "Описание", duration_minutes: 30)
    travel_to Time.utc(2026, 11, 15, 6, 0) do
      get "/api/event_types/#{event_type.id}/availability"
      assert_response :success
      body = response.parsed_body
      assert_equal "Europe/Moscow", body.fetch("time_zone")
      assert_equal 14, body.fetch("days").size
      assert_equal "2026-11-15", body["days"].first["date"]
      slots = body["days"].first.fetch("slots")
      assert_equal "2026-11-15T09:15:00+03:00", slots.first.fetch("starts_at")
      assert_equal "2026-11-15T17:30:00+03:00", slots.last.fetch("starts_at")
    end
  end

  test "validates input, booking window, grid and working hours" do
    event_type = EventType.create!(name: "Встреча", description: "Описание", duration_minutes: 30)
    travel_to Time.utc(2026, 11, 15, 6) do
      [ "2026-11-15T09:00:00+03:00", "2026-11-15T09:01:00+03:00", "2026-11-15T17:45:00+03:00", "2026-11-29T10:00:00+03:00", "2026-11-15T10:00:00", "bad" ].each do |time|
        post "/api/bookings", params: { event_type_id: event_type.id, starts_at: time }, as: :json
        assert_response :unprocessable_entity
        assert_equal "invalid_start_time", response.parsed_body.dig("error", "code")
      end
      post "/api/bookings", params: { event_type_id: "1", starts_at: "2026-11-15T10:00:00+03:00" }, as: :json
      assert_response :unprocessable_entity
      assert_equal "validation_error", response.parsed_body.dig("error", "code")
      get "/api/event_types/invalid/availability"
      assert_response :unprocessable_entity
      get "/api/event_types/999999/availability"
      assert_response :not_found
      post "/api/bookings", params: "{", headers: { "CONTENT_TYPE" => "application/json" }
      assert_response :bad_request
      assert_equal "invalid_json", response.parsed_body.dig("error", "code")
    end
  end

  test "availability excludes slots overlapping another type" do
    long = EventType.create!(name: "Длинный", description: "Описание", duration_minutes: 30)
    short = EventType.create!(name: "Короткий", description: "Описание", duration_minutes: 15)
    travel_to Time.utc(2026, 11, 15, 6) do
      post "/api/bookings", params: { event_type_id: long.id, starts_at: "2026-11-15T10:00:00+03:00" }, as: :json
      get "/api/event_types/#{short.id}/availability"
      slots = response.parsed_body.fetch("days").first.fetch("slots").pluck("starts_at")
      assert_not_includes slots, "2026-11-15T10:00:00+03:00"
      assert_not_includes slots, "2026-11-15T10:15:00+03:00"
      assert_includes slots, "2026-11-15T10:30:00+03:00"
      busy = response.parsed_body.fetch("days").first.fetch("busy_slots").pluck("starts_at")
      assert_includes busy, "2026-11-15T10:00:00+03:00"
      assert_includes busy, "2026-11-15T10:15:00+03:00"
      assert_not_includes busy, "2026-11-15T10:30:00+03:00"
      get "/api/event_types/#{long.id}/availability"
      busy = response.parsed_body.fetch("days").first.fetch("busy_slots").pluck("starts_at")
      assert_includes busy, "2026-11-15T09:45:00+03:00"
      assert_not_includes busy, "2026-11-15T10:30:00+03:00"
    end
  end

  test "displayed boundary slots can be booked and fractional or out of window starts cannot" do
    event_type = EventType.create!(name: "Встреча", description: "Описание", duration_minutes: 30)
    travel_to Time.utc(2026, 11, 15, 6) do
      get "/api/event_types/#{event_type.id}/availability"
      days = response.parsed_body.fetch("days")
      [ days.first.fetch("slots").last, days.last.fetch("slots").first ].each do |slot|
        post "/api/bookings", params: { event_type_id: event_type.id, starts_at: slot.fetch("starts_at") }, as: :json
        assert_response :created
        assert_equal slot.fetch("ends_at"), response.parsed_body.fetch("ends_at")
      end

      [ "2026-11-15T09:15:00.001+03:00", "2026-11-29T06:00:00Z", "2026-11-15T05:45:00Z" ].each do |starts_at|
        post "/api/bookings", params: { event_type_id: event_type.id, starts_at: starts_at }, as: :json
        assert_response :unprocessable_entity
        assert_equal "invalid_start_time", response.parsed_body.dig("error", "code")
      end
    end
  end

  test "booking input requires integer id and string start" do
    [ { event_type_id: 1.0, starts_at: "2026-11-15T10:00:00+03:00" },
      { event_type_id: true, starts_at: "2026-11-15T10:00:00+03:00" },
      { event_type_id: 1, starts_at: [ "2026-11-15T10:00:00+03:00" ] } ].each do |input|
      post "/api/bookings", params: input, as: :json
      assert_response :unprocessable_entity
      assert_equal "validation_error", response.parsed_body.dig("error", "code")
    end
  end
end
