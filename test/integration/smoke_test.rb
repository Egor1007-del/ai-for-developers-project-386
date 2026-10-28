require "test_helper"

class SmokeTest < ActionDispatch::IntegrationTest
  test "application and health endpoint respond successfully" do
    get root_path
    assert_response :success
    assert_select "h1", "Календарь звонков"
    assert_select "link[rel=stylesheet][href*='application']"
    assert_select "script[type=importmap]", text: /@hotwired\/turbo-rails/
    assert_select "script[type=importmap]", text: /@hotwired\/stimulus/

    get rails_health_check_path
    assert_response :success
  end
end
