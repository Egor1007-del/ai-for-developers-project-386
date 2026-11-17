require "test_helper"

class BookingConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    Booking.delete_all
    EventType.delete_all
  end

  teardown do
    Booking.delete_all
    EventType.delete_all
  end

  test "an uncommitted overlapping write makes the booking API unavailable until it can report a conflict" do
    type = EventType.create!(name: "Звонок", description: "Описание", duration_minutes: 30)
    result = Queue.new
    travel_to Time.utc(2026, 11, 15, 6) do
      Booking.transaction do
        Booking.create!(event_type: type, starts_at: Time.utc(2026, 11, 15, 7), ends_at: Time.utc(2026, 11, 15, 7, 30))
        thread = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            if connection.adapter_name == "PostgreSQL"
              connection.execute("SET lock_timeout = '250ms'")
            else
              connection.raw_connection.busy_timeout(250)
            end
            session = ActionDispatch::Integration::Session.new(Rails.application)
            session.post "/api/bookings", params: { event_type_id: type.id, starts_at: "2026-11-15T10:00:00+03:00" }, as: :json
            result << [ session.response.status, session.response.parsed_body ]
          ensure
            if connection.adapter_name == "PostgreSQL"
              connection.execute("RESET lock_timeout")
            else
              connection.raw_connection.busy_timeout(5000)
            end
          end
        end
        assert thread.join(10), "booking request did not finish while the conflicting transaction was open"
        status, body = result.pop
        assert_equal 503, status
        assert_equal "service_unavailable", body.dig("error", "code")
      ensure
        thread&.kill
        thread&.join
      end

      session = ActionDispatch::Integration::Session.new(Rails.application)
      session.post "/api/bookings", params: { event_type_id: type.id, starts_at: "2026-11-15T10:00:00+03:00" }, as: :json
      assert_equal 409, session.response.status
      assert_equal "booking_conflict", session.response.parsed_body.dig("error", "code")
      assert_equal 1, Booking.count
    end
  end

  test "simultaneous requests for the same slot return one conflict" do
    types = [ 15, 30 ].map do |duration|
      EventType.create!(name: "Звонок", description: "Описание", duration_minutes: duration)
    end
    ready = Queue.new
    start = Queue.new
    travel_to Time.utc(2026, 11, 15, 6) do
      threads = types.map do |type|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            session = ActionDispatch::Integration::Session.new(Rails.application)
            ready << connection.object_id
            start.pop
            session.post "/api/bookings", params: { event_type_id: type.id, starts_at: "2026-11-15T10:00:00+03:00" }, as: :json
            [ session.response.status, session.response.parsed_body ]
          end
        end
      end
      assert_not_equal ready.pop, ready.pop
      2.times { start << true }
      responses = threads.map(&:value)
      assert_equal [ 201, 409 ], responses.map(&:first).sort
      assert_equal "booking_conflict", responses.find { |status, _| status == 409 }.last.dig("error", "code")
      assert_equal 1, Booking.count
    end
  end

  test "independent connections cannot insert overlapping bookings and updates are protected" do
    first_type = EventType.create!(name: "Короткий", description: "Описание", duration_minutes: 15)
    second_type = EventType.create!(name: "Длинный", description: "Описание", duration_minutes: 30)
    ready = Queue.new
    start = Queue.new
    threads = [ first_type.id, second_type.id ].map do |type_id|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          ready << connection.object_id
          start.pop
          begin
            Booking.create!(event_type_id: type_id, starts_at: Time.utc(2030, 1, 1, 7), ends_at: Time.utc(2030, 1, 1, 7, 30))
            :created
          rescue ActiveRecord::StatementInvalid => error
            error.cause
          end
        end
      end
    end
    assert_not_equal ready.pop, ready.pop
    2.times { start << true }
    results = threads.map(&:value)
    assert_equal 1, results.count(:created)
    failure = results.find { |result| result != :created }
    assert [ SQLite3::ConstraintException, SQLite3::BusyException, SQLite3::LockedException, PG::ExclusionViolation ].any? { |type| failure.is_a?(type) }, failure.inspect
    assert_equal 1, Booking.count

    adjacent = Booking.create!(event_type: first_type, starts_at: Time.utc(2030, 1, 1, 7, 30), ends_at: Time.utc(2030, 1, 1, 7, 45))
    assert_raises(ActiveRecord::StatementInvalid) do
      adjacent.update!(starts_at: Time.utc(2030, 1, 1, 7, 15))
    end
    assert_equal 2, Booking.count
    adjacent.reload.update!(ends_at: Time.utc(2030, 1, 1, 8))
  end
end
