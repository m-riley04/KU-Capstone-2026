import { connectionType, createDbConnect } from "../db";
import { databaseNotification } from "../models/notifications";

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

export const addNotificationsToDatabase = async (connection: connectionType, notifications: databaseNotification[]) => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    for (const notification of notifications) {
        await db.run(
            `INSERT INTO polypod_notifications (user_id, notifType, from_source, notification_data, is_read, created_at) VALUES (?, ?, ?, ?, ?, ?)`,
            notification.user_id,
            notification.notifType,
            notification.from_source,
        JSON.stringify(notification.notification_data),
        notification.is_read,
        notification.created_at
    );}   
    await db.close();
};