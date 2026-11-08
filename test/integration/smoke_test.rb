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

    get rails_health_check_path
    assert_response :success
  end

  test "placeholder pages are accessible from navigation" do
    get booking_path
    assert_response :success
    assert_select "h1", "Страница записи скоро появится"
    assert_select "a[href=?]", root_path, text: "На главную"

    get admin_path
    assert_response :success
    assert_select "h1", "Админка скоро появится"
    assert_select "a[href=?]", root_path, text: "На главную"
  end
end
