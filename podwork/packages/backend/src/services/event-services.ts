import { createDbConnect } from "../db";
import {addEventToDatabase} from "../repositories/event_quaries";
import { eventData } from "../models/notifications";

export const setEventServices = async (event: eventData, interestName: string = 'apod') : Promise<void> => {
    try {
        await addEventToDatabase(1, event, interestName);
    } catch (error) {
        console.error('Error setting event services:', error);
        throw error;
    }
}