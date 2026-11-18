[
  { name: "Знакомство", description: "Короткий звонок для знакомства", duration_minutes: 15 },
  { name: "Обсуждение", description: "Встреча для подробного обсуждения", duration_minutes: 30 }
].each do |attributes|
  EventType.find_or_create_by!(name: attributes[:name], duration_minutes: attributes[:duration_minutes]) do |event_type|
    event_type.assign_attributes(attributes)
  end
end
