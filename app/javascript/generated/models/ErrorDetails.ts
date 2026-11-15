/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
export type ErrorDetails = {
    code: ErrorDetails.code;
    message: string;
    fields?: Record<string, Array<string>>;
};
export namespace ErrorDetails {
    export enum code {
        INVALID_JSON = 'invalid_json',
        EVENT_TYPE_NOT_FOUND = 'event_type_not_found',
        VALIDATION_ERROR = 'validation_error',
        INVALID_START_TIME = 'invalid_start_time',
        BOOKING_CONFLICT = 'booking_conflict',
        SERVICE_UNAVAILABLE = 'service_unavailable',
        INTERNAL_ERROR = 'internal_error',
    }
}

