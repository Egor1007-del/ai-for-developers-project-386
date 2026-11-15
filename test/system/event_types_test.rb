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
    click_link "Создать тип события"
    assert_text "Новый тип события"
  end

  test "owner creates an event type which the guest can see" do
    visit admin_path
    click_link "Создать тип события"
    assert_current_path new_admin_event_type_path
    fill_in "Название", with: "Консультация"
    fill_in "Описание", with: "Разговор о проекте"
    select "30 минут", from: "Длительность"
    click_button "Создать тип события"
    assert_current_path booking_path
    assert_text "Консультация"
    assert_text "Разговор о проекте"
    assert_text "30 минут"
  end

  test "owner sees validation errors by the fields" do
    visit new_admin_event_type_path
    fill_in "Название", with: "   "
    fill_in "Описание", with: "   "
    click_button "Создать тип события"
    assert_selector "#name-error", text: /.+/
    assert_selector "#description-error", text: /.+/
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
