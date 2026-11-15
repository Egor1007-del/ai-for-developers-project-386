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

  test "creates an event type and exposes it in the list" do
    post "/api/event_types", params: { name: "Встреча", description: "Описание", duration_minutes: 30, id: 999 }, as: :json

    assert_response :created
    created = response.parsed_body
    assert_kind_of Integer, created.fetch("id")
    assert_not_equal 999, created.fetch("id")
    assert_equal "Встреча", created.fetch("name")
    assert_equal "Описание", created.fetch("description")
    assert_equal 30, created.fetch("duration_minutes")
    get "/api/event_types"
    assert_includes response.parsed_body.fetch("data"), created
  end

  test "rejects invalid field values with field errors" do
    post "/api/event_types", params: { name: "  ", description: "x" * 1001, duration_minutes: "15" }, as: :json

    assert_response :unprocessable_entity
    error = response.parsed_body.fetch("error")
    assert_equal "validation_error", error.fetch("code")
    assert_equal %w[description duration_minutes name], error.fetch("fields").keys.sort
  end

  test "returns invalid_json for malformed JSON" do
    post "/api/event_types", params: '{"name":', headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :bad_request
    assert_equal "invalid_json", response.parsed_body.dig("error", "code")
  end
end
