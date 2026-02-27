import { connectionType, createDbConnect } from "../db";

export const getNotificationsFromDatabase = async (connection: connectionType, userId: number) => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    const notifications = await db.all(
        `SELECT notifType, from_source, notification_data FROM polypod_notifications WHERE user_id = ? AND is_read = FALSE ORDER BY created_at DESC`,
        userId
    );
    await db.close();
    return notifications ?? [];
};