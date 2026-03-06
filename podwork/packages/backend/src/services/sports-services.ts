import { eventData } from "../models/notifications";
import { getSportsDataFromDatabase } from "../repositories/sports_queries";

export const getPreviousSportsData = async (sportType: string): Promise<eventData | null> => {
    try {
        const previousSportsData = await getSportsDataFromDatabase(1, sportType);
        if (!previousSportsData) {
            console.log(`No previous ${sportType} data found in the database.`);
            return null;
        }
        return previousSportsData;
    } catch (error) {
        console.error(`Error fetching previous ${sportType} data:`, error);
        throw error;
    }
};
