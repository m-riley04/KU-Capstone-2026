import { eventData } from "../models/notifications";
import { getApodDataFromDatabase } from "../repositories/nasa_queries";

export const getPreviousApodData: () => Promise<eventData | null> = async () => {
    try { 
        const previousApodData = await getApodDataFromDatabase(1);
        if (!previousApodData) {
            console.log('No previous APOD data found in the database.');
            return null; 
        }
        return previousApodData;
    } catch (error) {
        console.error('Error fetching previous APOD data:', error);
        throw error;
    }
}