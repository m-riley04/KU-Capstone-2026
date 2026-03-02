import { get } from "node:http";
import { connectionType, createDbConnect } from "../db";
import { eventData } from "../models/notifications";

export const addEventToDatabase = async (connection: connectionType, event: eventData) => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    //wish this wasn't hardcoded, but can't think of better way to do this
    const getInterestIDFromName = await db.get(`SELECT id FROM interests WHERE name = 'apod'`);
    await db.run(
        `INSERT INTO polypod_events (interest_id, from_source, headline, info, created_at, media, seemore) VALUES (?, ?, ?, ?, ?, ?, ?)`,
        getInterestIDFromName.id,
        event.from_source,
        event.headline,
        event.info,
        event.timestamp,
        event.media,
        event.seemore
    );
    const events = await getEventsFromInterests(connection, [getInterestIDFromName.id]);
    await db.close();
    
}

export const getEventsFromInterests = async (connection: connectionType, interestIds: number[]) => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    
    const placeholders = interestIds.map(() => '?').join(',');
    const events = await db.all(
        `SELECT * FROM polypod_events WHERE interest_id IN (${placeholders}) ORDER BY created_at DESC`, interestIds.map(id => id.toString()));
    await db.close();
    
    if (!events || events.length === 0) {
        return [];
    }
    
    return events;
}