import { fetchApodData } from "../clients/NASA-client";
import { setEventServices } from "../services/event-services";
import { getPreviousApodData } from "../services/nasa-services";
import { generateNotifications } from "../services/notification_services-services";


export const getNasaApod: () => Promise<void> = async () => {
    try {
        const currentApodData = await fetchApodData();
        const oldApodData = await getPreviousApodData();
        if (!oldApodData) {
            console.log('No previous APOD data found. Adding current data and generating notification.');
            await setEventServices(currentApodData);
            await generateNotifications("apod");
        }
        else if (currentApodData && oldApodData && currentApodData.timestamp === oldApodData.timestamp) {
            console.log('APOD data has not changed since the last fetch. Skipping notification.');
        } 
        else {
            await setEventServices(currentApodData);
            await generateNotifications("apod");
        }
    } catch (error) {
        console.error('Error fetching APOD data:', error);
        throw error;
    }
}