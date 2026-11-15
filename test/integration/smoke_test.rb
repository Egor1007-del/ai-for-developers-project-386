require "test_helper"

class SmokeTest < ActionDispatch::IntegrationTest
  test "application and health endpoint respond successfully" do
    get root_path
    assert_response :success
    assert_select "h1", "Calendar"
    assert_select "h2", "Возможности"
    assert_select "a[href=?]", booking_path, text: /Записаться/, count: 2
    assert_select "a[href=?]", admin_path, text: "Админка"
    assert_select "link[rel=stylesheet][href*='application']"
    assert_select "script[type=module][src*='application'][data-turbo-track=reload]"

    get rails_health_check_path
    assert_response :success
  end

  test "booking and admin pages are accessible from navigation" do
    get booking_path
    assert_response :success
    assert_select "h1", "Boss"
    assert_select "a[href=?]", root_path, text: "На главную"

    get admin_path
    assert_response :success
    assert_select "h1", "Админка"
    assert_select "a[href=?]", new_admin_event_type_path, text: "Создать тип события"
    assert_select "a[href=?]", root_path, text: "На главную"

    get new_admin_event_type_path
    assert_response :success
    assert_select "h1", "Новый тип события"
    assert_select "a[href=?]", admin_path, text: "В админку"
  end
end
