require "application_system_test_case"

class UpcomingBookingsSystemTest < ApplicationSystemTestCase
  test "owner sees an empty state and can retry a failed request" do
    visit root_path
    page.execute_script <<~JS
      window.originalFetch = window.fetch
      window.fetch = (url, options) => String(url).includes("/api/bookings/upcoming")
        ? Promise.reject(new Error("network error"))
        : window.originalFetch(url, options)
    JS
    click_link "Админка"
    within "#upcoming-bookings" do
      assert_text "Не удалось загрузить предстоящие записи"
      page.execute_script "window.fetch = window.originalFetch"
      click_button "Повторить"
      assert_text "Предстоящих записей пока нет"
    end
  end

  test "owner sees upcoming bookings of different types in chronological order in Moscow time" do
    short = EventType.create!(name: "Короткий звонок", description: "Описание", duration_minutes: 15)
    long = EventType.create!(name: "Длинный звонок", description: "Описание", duration_minutes: 30)
    tomorrow = (Time.current.in_time_zone("Europe/Moscow").to_date + 1).in_time_zone("Europe/Moscow")
    Booking.create!(event_type: long, starts_at: tomorrow + 11.hours, ends_at: tomorrow + 11.hours + 30.minutes)
    Booking.create!(event_type: short, starts_at: tomorrow + 10.hours, ends_at: tomorrow + 10.hours + 15.minutes)
    Booking.create!(event_type: short, starts_at: 1.hour.ago, ends_at: 45.minutes.ago)

    visit admin_path

    within "#upcoming-bookings" do
      assert_text "Короткий звонок"
      assert_text "Длинный звонок"
      assert_text "10:00"
      assert_text "10:15"
      assert_text "11:00"
      assert_text "11:30"
      assert_text tomorrow.strftime("%d.%m.%Y")
      assert_equal [ "Короткий звонок", "Длинный звонок" ], all("li h3").map(&:text)
    end
  end
end
