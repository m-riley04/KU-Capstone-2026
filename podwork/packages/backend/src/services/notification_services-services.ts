import { databaseNotification, eventData, polypodNotification } from "../models/notifications";
import { getEventsFromInterests } from "../repositories/event_quaries";
import { getInterestIDFromName, getUserIdWithInterestFromDatabase } from "../repositories/interests_queries";
import { addNotificationsToDatabase, getNotificationsFromDatabase } from "../repositories/notifications_quaries";
import notification_services from "../routes/notification_services-routes";

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

//TODO: Add function to mark notifications as read in the database, and then call that function in the controller after successfully sending notifications to the device.

export const generateNotifications = async (interestName: string) : Promise<void> => {
    try {
        const interestId = await getInterestIDFromName(1, interestName);
        const interstid = interestId?.id;
        const event_data: eventData[] = await getEventsFromInterests(1, [interstid]);
        const userIds = await getUserIdWithInterestFromDatabase(1, interstid);
        if (!userIds || userIds.length === 0) {
            console.log('No users found with interest:', interestName);
            return;
        }
        const notifications: databaseNotification[] = [];
        for (const user of userIds) {
            const firstEvent = event_data[0];
            if (!firstEvent) {
                continue;
            }
            const notification: databaseNotification = {
                user_id: user.id,
                notifType: 'base',
                from_source: firstEvent.from_source, //TODO: This is a bit hacky, but for now we can just use the title of the event as the from_source. We can always add more fields to the databaseNotification model later if we want to include more information about the event in the notification.
                notification_data: firstEvent,
                is_read: false,
                created_at: new Date(),
            };
            notifications.push(notification);
        }
        await addNotificationsToDatabase(1, notifications);
        return;
    }catch (error) {
        console.error('Error generating notifications:', error);
        throw error;
    }
}