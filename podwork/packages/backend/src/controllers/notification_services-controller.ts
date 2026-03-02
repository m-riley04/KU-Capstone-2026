import { Request, Response } from 'express';
import { format } from 'node:path';
import { getNotificationsService } from '../services/notification_services-services';

export const getNotificationRequest = async (req: Request, res: Response) => {
    if (!req.params.userId || Array.isArray(req.params.userId)) {
        return res.status(400).json({ error: 'Valid User ID is required' });
    }
    const userId = parseInt(req.params.userId);
    try {
        const notifications = await getNotificationsService(userId);
        if (!notifications) {
            return res.status(204).json({ message: 'No notifications found' });
        }
        return res.status(200).json(notifications);
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch notifications' });
    }
}