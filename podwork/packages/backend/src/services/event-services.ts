import {addEventToDatabase} from "../repositories/event_quaries";
import { eventData } from "../models/notifications";

export const setEventServices = async (event: eventData) : Promise<void> => {
    try {
        await addEventToDatabase(1, event);
    } catch (error) {
        console.error('Error setting event services:', error);
        throw error;
    }
}