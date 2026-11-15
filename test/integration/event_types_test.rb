require "test_helper"

class EventTypesTest < ActionDispatch::IntegrationTest
  setup { EventType.delete_all }

  test "lists event types with their details" do
    EventType.create!(name: "Знакомство", description: "Короткий звонок", duration_minutes: 15)
    EventType.create!(name: "Обсуждение", description: "Подробный звонок", duration_minutes: 30)

    get "/api/event_types"

    assert_response :success
    assert_equal [
      { "id" => EventType.first.id, "name" => "Знакомство", "description" => "Короткий звонок", "duration_minutes" => 15 },
      { "id" => EventType.last.id, "name" => "Обсуждение", "description" => "Подробный звонок", "duration_minutes" => 30 }
    ], response.parsed_body.fetch("data")
  end

  test "returns an empty list when there are no event types" do
    get "/api/event_types"

    assert_response :success
    assert_equal [], response.parsed_body.fetch("data")
  end
end
