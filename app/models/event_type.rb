class EventType < ApplicationRecord
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :duration_minutes, inclusion: { in: [ 15, 30 ] }
end
