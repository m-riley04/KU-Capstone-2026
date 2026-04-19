import { eventData } from "../models/notifications";
import { getLatestEventByInterestName } from "../repositories/event_quaries";

export const getPreviousWeatherData = async (location: string): Promise<eventData | null> => {
    try {
        const interestName = `weather_${location}`;

        const previousData = await getLatestEventByInterestName(1, interestName);
        
        if (!previousData) {
            console.log(`No previous weather data found in the database for ${location}.`);
            return null;
        }

        return previousData;
    } catch (error) {
        console.error(`Error fetching previous weather data for ${location}:`, error);
        throw error;
    }
}

export const weatherDataHasChanged = (currentData: eventData, oldData: eventData | null): boolean => {
    if (!oldData) {
        return true;
    }

    // severe Weather Alerts
    const isCurrentAlert = currentData.headline.includes('ALERT');
    const isOldAlert = oldData.headline.includes('ALERT');

    // new alert or alert changed
    if (isCurrentAlert && ( currentData.info !== oldData.info ) ) {
        return true;
    }

    // alert expired or ended
    if (!isCurrentAlert && isOldAlert) {
        return true;
    }

    // handle Normal Weather
    if (!isCurrentAlert && !isOldAlert) {
        const currentCondition = currentData.info.split('and ')[1];
        const oldCondition = oldData.info.split('and ')[1];

        if (currentCondition && oldCondition && currentCondition !== oldCondition) {
            return true;
        }
    }

    return false;
}