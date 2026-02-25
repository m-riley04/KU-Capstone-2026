import { connectionType, createDbConnect } from "../db";
import { UserInterests } from "../models/user";

export const addUserInterestToDatabase = async (connection: connectionType, userId: number, interestId: number) => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    await db.run(
        `INSERT INTO user_interests (user_id, interest_id) VALUES (?, ?)`,
        userId,
        interestId
    );
    await db.close();
    return { userId, interestId };
}

export const getUserInterestsFromDatabase = async (connection: connectionType, userId: number) => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    const interests = await db.all(
        `SELECT i.id, i.name, i.category FROM interests i
        JOIN user_interests ui ON i.id = ui.interest_id
        WHERE ui.user_id = ?`,
        userId
    );
    await db.close();
    return interests;
}

export const getInterests = async (connection: connectionType, interest: UserInterests) => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    const interestData = await db.get(`SELECT * FROM interests WHERE name = ?`, interest.name);
    if (!interestData) {
        throw new Error('Interest not found');
    }
    await db.close();
    return interestData;
}

const addInterestToDatabase = async (connection: connectionType, name: string, category: string) => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    try {
        const result = await db.run(
            `INSERT INTO interests (name, category) VALUES (?, ?)`,
            name,
            category
        );
        const newInterestId = result.lastID;
        const newInterest = await db.get(`SELECT * FROM interests WHERE id = ?`, newInterestId);
        await db.close();
        return newInterest ?? null;
    } catch (error: any) {
        if (error.code === 'SQLITE_CONSTRAINT' && error.message.includes('name')) {
            await db.close();
            throw new Error('Interest name already exists');
        }
        await db.close();
    }
}