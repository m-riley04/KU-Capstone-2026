export interface polypodNotification {
    notifType: string;
    from_source: string;
    data: notificationData; 
}
//TODO: Delete if don't use later
export interface databaseNotification {
    notifType: string;
    from_source: string;
    notification_data: notificationData; // Stored as JSON string in the database
    is_read: boolean;
    created_at: Date;
}

export interface notificationData {
    timestamp: Date;
    media: string; //HANNAH IS THIS RIGHT? 
    headline: string;
    info: string;
    seemore: string;
}