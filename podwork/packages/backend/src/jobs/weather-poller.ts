import { fetchWeatherData } from "../clients/weather-client";
import { setEventServices } from "../services/event-services";
import { getPreviousWeatherData, weatherDataHasChanged } from "../services/weather-services";
import { generateNotifications } from "../services/notification_services-services";

const LOCATION = '66044'; 

export const getWeatherUpdates: () => Promise<void> = async () => {
    try {
        const weatherInterestId = `weather_${LOCATION}`;
        
        const currentWeatherData = await fetchWeatherData(LOCATION);
        const oldWeatherData = await getPreviousWeatherData(LOCATION);

        // only trigger a notification if
        // 1. new sever weather alert was issued
        // 2. user explicitly requested a daily morning summary
        if (!weatherDataHasChanged(currentWeatherData, oldWeatherData)) {
            console.log(`No significant weather changes for ${LOCATION}. Skipping.`);
            return;
        }

        await setEventServices(currentWeatherData, weatherInterestId);
        await generateNotifications(weatherInterestId);
        console.log(`Significant weather event in ${LOCATION}! Event saved and notifications generated.`);
    } catch (error) {
        console.error('Error fetching Weather data:', error);
        throw error;
    }
}