import { connectionType, createDbConnect } from "../db";
import { eventData } from "../models/notifications";

export const getSportsDataFromDatabase = async (connection: connectionType, sportType: string): Promise<eventData | null> => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    
    try {
        // Get the interest ID for the sport type (e.g., 'cbb', 'nfl')
        const getInterestIDFromName = await db.get(
            `SELECT id FROM interests WHERE name = ?`,
            [sportType]
        );
        
        if (!getInterestIDFromName) {
            console.log(`No interest found for sport type: ${sportType}`);
            return null;
        }
        
        // Get the most recent sports event for this interest
        const previousSportsData = await db.get(
            `SELECT * FROM polypod_events WHERE interest_id = ? ORDER BY created_at DESC LIMIT 1`,
            [getInterestIDFromName.id]
        );
        
        if (!previousSportsData) {
            console.log(`No previous ${sportType} data found in the database.`);
            return null;
        }
        
        console.log(`Previous ${sportType} data retrieved from database:`, previousSportsData);
        
        const eventData: eventData = {
            from_source: previousSportsData.from_source,
            headline: previousSportsData.headline,
            info: previousSportsData.info,
            timestamp: previousSportsData.created_at,
            media: previousSportsData.media,
            seemore: previousSportsData.seemore
        };
        
        return eventData;
    } finally {
        await db.close();
    }
};
