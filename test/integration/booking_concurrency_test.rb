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

  test "independent connections cannot insert overlapping bookings and updates are protected" do
    first_type = EventType.create!(name: "Короткий", description: "Описание", duration_minutes: 15)
    second_type = EventType.create!(name: "Длинный", description: "Описание", duration_minutes: 30)
    inserted = Queue.new
    release = Queue.new
    committed = Queue.new
    writer = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.transaction do
          Booking.create!(event_type_id: first_type.id, starts_at: Time.utc(2030, 1, 1, 7), ends_at: Time.utc(2030, 1, 1, 7, 30))
          inserted << connection.object_id
          release.pop
        end
        committed << true
      end
    end
    first_connection = inserted.pop
    contender = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        release << true
        committed.pop
        error = assert_raises(ActiveRecord::StatementInvalid) do
          Booking.create!(event_type_id: second_type.id, starts_at: Time.utc(2030, 1, 1, 7, 15), ends_at: Time.utc(2030, 1, 1, 7, 45))
        end
        [ connection.object_id, error ]
      end
    end
    second_connection, error = contender.value
    writer.value
    assert_not_equal first_connection, second_connection
    assert_includes error.message, "booking_conflict"
    assert_equal 1, Booking.count

    adjacent = Booking.create!(event_type: first_type, starts_at: Time.utc(2030, 1, 1, 7, 30), ends_at: Time.utc(2030, 1, 1, 7, 45))
    assert_raises(ActiveRecord::StatementInvalid) do
      adjacent.update!(starts_at: Time.utc(2030, 1, 1, 7, 15))
    end
    assert_equal 2, Booking.count
    adjacent.reload.update!(ends_at: Time.utc(2030, 1, 1, 8))
  end
end
