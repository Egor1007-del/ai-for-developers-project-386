require "application_system_test_case"

class BookingsSystemTest < ApplicationSystemTestCase
  test "booking controls stay disabled until the response and availability refresh complete" do
    EventType.create!(name: "Первый", description: "Описание", duration_minutes: 15)
    EventType.create!(name: "Второй", description: "Описание", duration_minutes: 30)
    visit booking_path
    click_button "Выбрать Первый"
    assert_text "Выберите дату (московское время)"
    within('[aria-label="Даты"]') { first("button:not([disabled])").click }
    within('[aria-label="Время"]') { first("button").click }
    selection = find('[data-event-types-target="selection"]').text
    page.execute_script <<~JS
      window.originalFetch = window.fetch;
      window.fetch = function(input, options) {
        if (String(input).includes('/api/bookings') && options?.method === 'POST') {
          return new Promise(resolve => { window.releaseBooking = () => resolve(window.originalFetch(input, options)); });
        }
        return window.originalFetch(input, options);
      };
    JS
    click_button "Подтвердить запись"
    assert_text "Создание записи…"
    assert_button "Назад", disabled: true
    assert_selector '[aria-label="Даты"] button:disabled', minimum: 1
    assert_selector '[aria-label="Время"] button:disabled', minimum: 1
    assert page.evaluate_script("document.querySelector('[data-event-types-target=confirm]').matches(':disabled')")
    assert_text selection
    page.execute_script "window.releaseBooking()"
    assert_text "Запись создана:"
    assert_text "Первый"
    assert_button "Назад", disabled: false
    assert_equal 1, Booking.count
  end

  test "calendar displays occupied slots and permits selecting adjacent free slots" do
    type = EventType.create!(name: "Звонок", description: "Описание", duration_minutes: 15)
    date = Time.current.in_time_zone("Europe/Moscow").to_date + 1
    start = Time.find_zone!("Europe/Moscow").local(date.year, date.month, date.day, 10)
    Booking.create!(event_type: type, starts_at: start, ends_at: start + 15.minutes)
    visit booking_path
    click_button "Выбрать Звонок"
    assert_text "Выберите дату (московское время)"
    if date.strftime("%Y-%m") != Time.current.in_time_zone("Europe/Moscow").strftime("%Y-%m")
      click_button "Следующий месяц"
    end
    find("[aria-label='Даты'] button[aria-label='#{date.iso8601}']").click
    within '[aria-label="Время"]' do
      assert_button "10:00 - 10:15 Занято", disabled: true
      assert_button "10:15 - 10:30 Свободно", disabled: false
      click_button "10:15 - 10:30 Свободно"
    end
    assert_text "Выбрано: #{date.iso8601}, 10:15"
  end

  test "guest selects and confirms a free slot" do
    EventType.create!(name: "Звонок", description: "Описание", duration_minutes: 15)
    visit booking_path
    click_button "Выбрать Звонок"
    assert_text "Выберите дату (московское время)"
    within '[aria-label="Даты"]' do
      first("button:not([disabled])").click
    end
    within '[aria-label="Время"]' do
      first("button").click
    end
    assert_text "Выбрано:"
    assert_equal 0, Booking.count
    click_button "Подтвердить запись"
    assert_text "Запись создана:"
    assert_equal 1, Booking.count
  end

  test "guest sees a conflict and refreshed availability" do
    type = EventType.create!(name: "Звонок", description: "Описание", duration_minutes: 15)
    visit booking_path
    click_button "Выбрать Звонок"
    assert_text "Выберите дату (московское время)"
    within '[aria-label="Даты"]' do
      first("button:not([disabled])").click
    end
    within '[aria-label="Время"]' do
      first("button").click
    end
    selected = find('[data-event-types-target="selection"]').text
    starts_at = Time.find_zone!("Europe/Moscow").parse(selected.match(/\d{4}-\d{2}-\d{2}, \d{2}:\d{2}/)[0].delete(","))
    Booking.create!(event_type: type, starts_at: starts_at, ends_at: starts_at + 15.minutes)
    click_button "Подтвердить запись"
    assert_text "Это время уже занято"
    assert_no_button "Подтвердить запись"
  end
end
