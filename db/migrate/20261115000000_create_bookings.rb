class CreateBookings < ActiveRecord::Migration[8.1]
  def up
    create_table :bookings do |t|
      t.references :event_type, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.timestamps
      t.check_constraint "ends_at > starts_at", name: "booking_positive_interval"
    end
    add_index :bookings, :starts_at
    if connection.adapter_name == "PostgreSQL"
      execute <<~SQL
        ALTER TABLE bookings ADD CONSTRAINT booking_no_overlap
        EXCLUDE USING gist (tsrange(starts_at, ends_at, '[)') WITH &&)
      SQL
    else
      execute <<~SQL
        CREATE TRIGGER bookings_no_overlap_insert BEFORE INSERT ON bookings
        WHEN EXISTS (SELECT 1 FROM bookings WHERE starts_at < NEW.ends_at AND ends_at > NEW.starts_at)
        BEGIN SELECT RAISE(ABORT, 'booking_conflict'); END;
      SQL
      execute <<~SQL
        CREATE TRIGGER bookings_no_overlap_update BEFORE UPDATE ON bookings
        WHEN EXISTS (SELECT 1 FROM bookings WHERE id != OLD.id AND starts_at < NEW.ends_at AND ends_at > NEW.starts_at)
        BEGIN SELECT RAISE(ABORT, 'booking_conflict'); END;
      SQL
    end
  end

  def down
    drop_table :bookings
  end
end
