import { eventData } from "../models/notifications";
import { getLatestEventByInterestName } from "../repositories/event_quaries";

const ESPN_SCOREBOARD_INTEREST = 'espn_mens_college_basketball_scoreboard';

export const getPreviousEspnScoreboardData: () => Promise<eventData | null> = async () => {
    try {
        const previousData = await getLatestEventByInterestName(1, ESPN_SCOREBOARD_INTEREST);
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
