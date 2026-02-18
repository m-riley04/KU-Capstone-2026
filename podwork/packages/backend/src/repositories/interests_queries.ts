import { createDbConnect } from "../db";
import { UserInterests } from "../models/user";

export const addUserInterestToDatabase = async (userId: number, interestId: number) => {
    const db = await createDbConnect(1);
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

export const getInterests = async (interest: UserInterests) => {
    const db = await createDbConnect(1);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    const interestData = await db.get(`SELECT * FROM interests WHERE name = ?`, interest.name);
    await db.close();
    return interestData;
}
