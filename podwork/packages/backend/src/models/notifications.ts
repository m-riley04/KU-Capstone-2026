export interface polypodNotification {
    notifType: string;
    from_source: string;
    data: eventData; 
}
//TODO: Delete if don't use later
export interface databaseNotification {
    user_id: number;
    notifType: string;
    from_source: string;
    notification_data: eventData; // Stored as JSON string in the database
    is_read: boolean;
    created_at: Date;
}

export interface eventData {
    timestamp: Date;
    from_source: string;
    media: string; //HANNAH IS THIS RIGHT? 
    headline: string;
    info: string;
    seemore: string;
}