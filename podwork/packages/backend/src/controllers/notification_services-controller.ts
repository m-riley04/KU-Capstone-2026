import { Request, Response } from 'express';
import { getNotificationsService } from '../services/notification_services-services';

export const getNotificationRequest = async (req: Request, res: Response) => {
    if (!req.params.deviceOrUserId || Array.isArray(req.params.deviceOrUserId)) {
        return res.status(400).json({ error: 'Valid device ID is required' });
    }
    const deviceOrUserId = req.params.deviceOrUserId.trim();

    if (!deviceOrUserId) {
        return res.status(400).json({ error: 'Valid device ID is required' });
    }

    try {
        const notifications = await getNotificationsService(deviceOrUserId);
        if (!notifications) {
            return res.status(204).json({ message: 'No notifications found' });
        }
        return res.status(200).json(notifications);
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch notifications' });
    }
}