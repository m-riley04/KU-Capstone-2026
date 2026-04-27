import { get } from "node:http";
import { connectionType, createDbConnect } from "../db";
import { eventData } from "../models/notifications";

export const addEventToDatabase = async (connection: connectionType, event: eventData, interestName: string = 'apod') => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    const getInterestIDFromName = await db.get(`SELECT id FROM interests WHERE name = ?`, interestName);
    if (!getInterestIDFromName) {
        await db.close();
        throw new Error(`Interest not found: ${interestName}`);
    }
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

export const getLatestEventByInterestName = async (connection: connectionType, interestName: string): Promise<eventData | null> => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }

    const interestIdRow = await db.get(`SELECT id FROM interests WHERE name = ?`, interestName);
    if (!interestIdRow) {
        await db.close();
        return null;
    }

    const latestEvent = await db.get(
        `SELECT * FROM polypod_events WHERE interest_id = ? ORDER BY created_at DESC LIMIT 1`,
        interestIdRow.id
    );

    await db.close();

    if (!latestEvent) {
        return null;
    }

    return {
        from_source: latestEvent.from_source,
        headline: latestEvent.headline,
        info: latestEvent.info,
        timestamp: latestEvent.created_at,
        media: latestEvent.media,
        seemore: latestEvent.seemore
    };
}

export const getLatestEventByInterestId = async (connection: connectionType, interestId: number): Promise<eventData | null> => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }

    const latestEvent = await db.get(
        `SELECT * FROM polypod_events WHERE interest_id = ? ORDER BY created_at DESC LIMIT 1`,
        interestId
    );

    await db.close();

    if (!latestEvent) {
        return null;
    }

    return {
        from_source: latestEvent.from_source,
        headline: latestEvent.headline,
        info: latestEvent.info,
        timestamp: latestEvent.created_at,
        media: latestEvent.media,
        seemore: latestEvent.seemore
    };
}

export const getLatestWeatherEventbyZip = async (connection: connectionType, zipcode: string): Promise<eventData | null> => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }

    const weatherSource = `weather_${zipcode}`;

    const latestEvent = await db.get(
        `SELECT * FROM polypod_events WHERE from_source = ? ORDER BY created_at DESC LIMIT 1`,
        weatherSource
    );

    await db.close();

    if (!latestEvent) {
        return null;
    }

    return {
        from_source: latestEvent.from_source,
        headline: latestEvent.headline,
        info: latestEvent.info,
        timestamp: latestEvent.created_at,
        media: latestEvent.media,
        seemore: latestEvent.seemore
    };
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