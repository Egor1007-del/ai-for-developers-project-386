require "application_system_test_case"

class EventTypesSystemTest < ApplicationSystemTestCase
  setup { EventType.delete_all }

  test "guest sees Boss and event types loaded from the API" do
    EventType.create!(name: "Знакомство", description: "Короткий звонок", duration_minutes: 15)
    EventType.create!(name: "Обсуждение", description: "Подробный звонок", duration_minutes: 30)

    visit booking_path

    assert_text "Boss"
    assert_text "Знакомство"
    assert_text "Короткий звонок"
    assert_text "15 минут"
    assert_text "Обсуждение"
    assert_text "Подробный звонок"
    assert_text "30 минут"
  end

  test "guest sees an empty state" do
    visit booking_path
    assert_text "Пока нет доступных типов событий"
  end

  test "guest can retry after a loading error" do
    visit root_path
    page.execute_script <<~JS
      window.originalFetch = window.fetch
      window.fetch = (url, options) => String(url).includes("/api/event_types")
        ? Promise.reject(new Error("network error"))
        : window.originalFetch(url, options)
    JS
    click_link "Записаться", match: :first
    assert_text "Не удалось загрузить типы событий"

    page.execute_script "window.fetch = window.originalFetch"
    click_button "Повторить"
    assert_text "Пока нет доступных типов событий"
  end
end
