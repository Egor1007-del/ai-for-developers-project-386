import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

using TypeSpec.Http;
using TypeSpec.OpenAPI;

@service(#{ title: "Calendar API" })
namespace Calendar;

model EventType {
  id: int32;
  @minLength(1) @maxLength(100) name: string;
  @minLength(1) @maxLength(1000) description: string;
  duration_minutes: 15 | 30;
}

model EventTypeInput {
  @minLength(1) @maxLength(100) name: string;
  @minLength(1) @maxLength(1000) description: string;
  duration_minutes: 15 | 30;
}

model Slot { starts_at: offsetDateTime; ends_at: offsetDateTime; }
model Day { date: plainDate; slots: Slot[]; busy_slots: Slot[]; }
model Availability { time_zone: string; days: Day[]; }
model Booking { id: int32; event_type: EventType; starts_at: offsetDateTime; ends_at: offsetDateTime; }
model BookingInput { event_type_id: int32; starts_at: offsetDateTime; }
model ErrorDetails {
  code: "invalid_json" | "event_type_not_found" | "validation_error" | "invalid_start_time" | "booking_conflict" | "service_unavailable" | "internal_error";
  message: string;
  fields?: Record<string[]>;
}
model ErrorBody { error: ErrorDetails; }
@doc("invalid_json: malformed JSON request body")
model BadRequest { @statusCode statusCode: 400; @body body: ErrorBody; }
@doc("event_type_not_found: the event type does not exist")
model NotFound { @statusCode statusCode: 404; @body body: ErrorBody; }
@doc("booking_conflict: the requested slot overlaps another booking")
model Conflict { @statusCode statusCode: 409; @body body: ErrorBody; }
@doc("validation_error for invalid or missing fields; invalid_start_time for a time outside the booking rules")
model Unprocessable { @statusCode statusCode: 422; @body body: ErrorBody; }
@doc("internal_error: unexpected server error without technical details")
model InternalError { @statusCode statusCode: 500; @body body: ErrorBody; }
@doc("service_unavailable: database lock wait exhausted")
model Unavailable { @statusCode statusCode: 503; @body body: ErrorBody; }
model Ok<T> { @statusCode statusCode: 200; @body body: T; }
model Created<T> { @statusCode statusCode: 201; @body body: T; }

@route("/api/event_types")
interface EventTypes {
  @get @operationId("listEventTypes")
  list(): Ok<{ data: EventType[] }> | InternalError;
  @post @operationId("createEventType")
  create(@body body: EventTypeInput): Created<EventType> | BadRequest | Unprocessable | InternalError;
  @get @route("/{id}/availability") @operationId("getAvailability")
  availability(@path id: int32): Ok<Availability> | NotFound | Unprocessable | Unavailable | InternalError;
}

@route("/api/bookings")
interface Bookings {
  @post @operationId("createBooking")
  create(@body body: BookingInput): Created<Booking> | BadRequest | NotFound | Conflict | Unprocessable | Unavailable | InternalError;
  @get @route("/upcoming") @operationId("listUpcomingBookings")
  upcoming(): Ok<{ data: Booking[] }> | InternalError;
}
