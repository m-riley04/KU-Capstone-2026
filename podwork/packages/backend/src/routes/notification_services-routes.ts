
import express from 'express';
import { getNotificationRequest } from '../controllers/notification_services-controller';


enum path {
    getNotifications  = '/:userId',
}

const notification_services = express.Router()

// authenticate notification service routes
notification_services.get(path.getNotifications, getNotificationRequest);

//export the notification services router
export default notification_services;