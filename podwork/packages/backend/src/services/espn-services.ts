import { eventData } from "../models/notifications";
import { getLatestEventByInterestName } from "../repositories/event_quaries";

export const getPreviousEspnScoreboardData: (scoreboard: string) => Promise<eventData | null> = async (scoreboard: string) => {
    try {
        const previousData = await getLatestEventByInterestName(1, scoreboard);
        if (!previousData) {
            console.log('No previous ESPN scoreboard data found in the database.');
            return null;
        }

        return previousData;
    } catch (error) {
        console.error('Error fetching previous ESPN scoreboard data:', error);
        throw error;
    }
}

export const espnScoreboardHasChanged = (currentData: eventData, oldData: eventData | null): boolean => {
    if (!oldData) {
        return true;
    }

    return currentData.headline !== oldData.headline || currentData.info !== oldData.info;
}
