/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
export type EventType = {
    id: number;
    name: string;
    description: string;
    duration_minutes: EventType.duration_minutes;
};
export namespace EventType {
    export enum duration_minutes {
        '_15' = 15,
        '_30' = 30,
    }
}

