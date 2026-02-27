import { polypodNotification } from "../models/notifications";
import { getNotificationsFromDatabase } from "../repositories/notifications_quaries";

export const getNotificationsService = async (userId: number): Promise<polypodNotification[] | null> => {
    try {
        const notifications = await getNotificationsFromDatabase(1, userId);
        if (!notifications || notifications.length === 0) {
            return null; 
        }
        // Map database notifications to polypodNotification format so 
        // that it's ready to send to devices without needing to do any additional formatting
        let formattedNotifications : polypodNotification[] = [];
        notifications.forEach(notification => {
            const formattedNotification  : polypodNotification =  {
                notifType: notification.notifType,
                from_source: notification.from_source,
                data: JSON.parse(notification.notification_data),
            }
            formattedNotifications.push(formattedNotification);
        });
        return formattedNotifications;
    } catch (error) {
        throw new Error('Failed to fetch notifications');
    }
}