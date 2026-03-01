import { connectionType, createDbConnect } from "../db";
import { eventData } from "../models/notifications";

//TODO: I will fix this syntax soon, just wanted to get working 
export const getApodDataFromDatabase: (connection: connectionType) => Promise<eventData | null> = async (connection: connectionType) => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    //wish this wasn't hardcoded, but can't think of better way to do this
    const getInterestIDFromName = await db.get(`SELECT id FROM interests WHERE name = 'apod'`);
    const previousApodData = await db.get(
        `SELECT * FROM polypod_events WHERE interest_id = ? ORDER BY created_at DESC LIMIT 1`,
        getInterestIDFromName.id
    );
    await db.close();
    if (!previousApodData) {
        console.log('No previous APOD data found in the database.');
        return null; 
    }
    console.log('Previous APOD data retrieved from database:', previousApodData);
    const eventData: eventData = {
        from_source: previousApodData.from_source,
        headline: previousApodData.headline,
        info: previousApodData.info,
        timestamp: previousApodData.created_at,
        media: previousApodData.media,
        seemore: previousApodData.seemore
    };
    return eventData;
}