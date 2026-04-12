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
            
            // pass the clean zip code directly to the API
            const currentWeatherData = await fetchWeatherData(zipCode);
            const oldWeatherData = await getPreviousWeatherData(zipCode);

            currentWeatherData.from_source = `weather_${zipCode}`;

            if (!weatherDataHasChanged(currentWeatherData, oldWeatherData)) {
                console.log(`No significant weather changes for ${zipCode}. Skipping.`);
                continue;
            }

            await addEventToDatabase(1, currentWeatherData, 'Weather Alerts');

            if (currentWeatherData.headline.includes('WEATHER ALERT')) {
                await generateTargetedWeatherNotifications(1, zipCode, currentWeatherData);
                console.log(`🚨 Severe notification sent for ${zipCode}`);
            }
            
            console.log(`Weather event successfully processed for ${zipCode}`);
        }
        
    } catch (error) {
        console.error('Error fetching Weather data:', error);
        throw error;
    }
}