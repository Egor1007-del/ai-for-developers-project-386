CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "event_types" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "description" text NOT NULL, "duration_minutes" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "bookings" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "event_type_id" integer NOT NULL, "starts_at" datetime(6) NOT NULL, "ends_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c99fd599ed"
FOREIGN KEY ("event_type_id")
  REFERENCES "event_types" ("id")
, CONSTRAINT booking_positive_interval CHECK (ends_at > starts_at));
CREATE INDEX "index_bookings_on_event_type_id" ON "bookings" ("event_type_id") /*application='CalendarCalls'*/;
CREATE INDEX "index_bookings_on_starts_at" ON "bookings" ("starts_at") /*application='CalendarCalls'*/;
CREATE TRIGGER bookings_no_overlap_insert BEFORE INSERT ON bookings
WHEN EXISTS (SELECT 1 FROM bookings WHERE starts_at < NEW.ends_at AND ends_at > NEW.starts_at)
BEGIN SELECT RAISE(ABORT, 'booking_conflict'); END;
CREATE TRIGGER bookings_no_overlap_update BEFORE UPDATE ON bookings
WHEN EXISTS (SELECT 1 FROM bookings WHERE id != OLD.id AND starts_at < NEW.ends_at AND ends_at > NEW.starts_at)
BEGIN SELECT RAISE(ABORT, 'booking_conflict'); END;
INSERT INTO "schema_migrations" (version) VALUES
('20261115000000'),
('20261112000000');
