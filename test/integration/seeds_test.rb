require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "seeds preserve existing records and create both initial durations only once" do
    Booking.delete_all
    EventType.delete_all
    existing = EventType.create!(name: "Знакомство", description: "Моё описание", duration_minutes: 30)
    initial = EventType.create!(name: "Обсуждение", description: "Другое описание", duration_minutes: 30)

    2.times { Rails.application.load_seed }

    assert_equal [ [ "Знакомство", 15 ], [ "Знакомство", 30 ], [ "Обсуждение", 30 ] ],
      EventType.order(:name, :duration_minutes).pluck(:name, :duration_minutes)
    assert_equal "Моё описание", existing.reload.description
    assert_equal "Другое описание", initial.reload.description
  end
end
