import { fetchWeatherData, getActiveWeatherZipCodes } from "../clients/weather-client";
import { setEventServices } from "../services/event-services";
import { getPreviousWeatherData, weatherDataHasChanged } from "../services/weather-services";
import { generateNotifications, generateTargetedWeatherNotifications } from "../services/notification_services-services";
import { eventData } from "../models/notifications";
import { addEventToDatabase } from "../repositories/event_quaries";



export const getWeatherUpdates = async () => {
    try {
        const activeZipCodes = await getActiveWeatherZipCodes();

        // loop through each zipcode
        for (const zipCode of activeZipCodes) {
            
            // We pass the clean zip code directly to the API
            const currentWeatherData = await fetchWeatherData(zipCode);
            const oldWeatherData = await getPreviousWeatherData(zipCode);

            if (!weatherDataHasChanged(currentWeatherData, oldWeatherData)) {
                console.log(`No significant weather changes for ${zipCode}. Skipping.`);
                continue; 
            }

            const newWeatherEvent: eventData = {
                from_source: `weather_${zipCode}`, 
                headline: `Weather Update for ${zipCode}`,
                info: `Whatever string you use for the description...`, 
                timestamp: new Date(),
                media: "", 
                seemore: ""
            };

            await addEventToDatabase(1, newWeatherEvent, 'weather_alerts');

            await generateTargetedWeatherNotifications(1, zipCode, newWeatherEvent);
            
            console.log(`Weather event successfully processed for ${zipCode}`);
        }
        
    } catch (error) {
        console.error('Error fetching Weather data:', error);
        throw error;
    }
}