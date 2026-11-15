/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Availability } from '../models/Availability';
import type { Booking } from '../models/Booking';
import type { BookingInput } from '../models/BookingInput';
import type { EventType } from '../models/EventType';
import type { EventTypeInput } from '../models/EventTypeInput';
import type { CancelablePromise } from '../core/CancelablePromise';
import { OpenAPI } from '../core/OpenAPI';
import { request as __request } from '../core/request';
export class DefaultService {
    /**
     * @param requestBody
     * @returns Booking The request has succeeded and a new resource has been created as a result.
     * @throws ApiError
     */
    public static createBooking(
        requestBody: BookingInput,
    ): CancelablePromise<Booking> {
        return __request(OpenAPI, {
            method: 'POST',
            url: '/api/bookings',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `invalid_json: malformed JSON request body`,
                404: `event_type_not_found: the event type does not exist`,
                409: `booking_conflict: the requested slot overlaps another booking`,
                422: `validation_error for invalid or missing fields; invalid_start_time for a time outside the booking rules`,
                500: `internal_error: unexpected server error without technical details`,
                503: `service_unavailable: database lock wait exhausted`,
            },
        });
    }
    /**
     * @returns any The request has succeeded.
     * @throws ApiError
     */
    public static listUpcomingBookings(): CancelablePromise<{
        data: Array<Booking>;
    }> {
        return __request(OpenAPI, {
            method: 'GET',
            url: '/api/bookings/upcoming',
            errors: {
                500: `internal_error: unexpected server error without technical details`,
            },
        });
    }
    /**
     * @returns any The request has succeeded.
     * @throws ApiError
     */
    public static listEventTypes(): CancelablePromise<{
        data: Array<EventType>;
    }> {
        return __request(OpenAPI, {
            method: 'GET',
            url: '/api/event_types',
            errors: {
                500: `internal_error: unexpected server error without technical details`,
            },
        });
    }
    /**
     * @param requestBody
     * @returns EventType The request has succeeded and a new resource has been created as a result.
     * @throws ApiError
     */
    public static createEventType(
        requestBody: EventTypeInput,
    ): CancelablePromise<EventType> {
        return __request(OpenAPI, {
            method: 'POST',
            url: '/api/event_types',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `invalid_json: malformed JSON request body`,
                422: `validation_error for invalid or missing fields; invalid_start_time for a time outside the booking rules`,
                500: `internal_error: unexpected server error without technical details`,
            },
        });
    }
    /**
     * @param id
     * @returns Availability The request has succeeded.
     * @throws ApiError
     */
    public static getAvailability(
        id: number,
    ): CancelablePromise<Availability> {
        return __request(OpenAPI, {
            method: 'GET',
            url: '/api/event_types/{id}/availability',
            path: {
                'id': id,
            },
            errors: {
                404: `event_type_not_found: the event type does not exist`,
                422: `validation_error for invalid or missing fields; invalid_start_time for a time outside the booking rules`,
                500: `internal_error: unexpected server error without technical details`,
                503: `service_unavailable: database lock wait exhausted`,
            },
        });
    }
}
