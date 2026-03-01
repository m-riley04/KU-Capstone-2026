

import express, { Request, Response } from 'express';
import cors from 'cors';
import user_services from './routes/users_services-routes';
import dotenv from 'dotenv';
import { runMigrations } from './db/run_migrations';
import { seedInterests } from './db/seed_interests';
import notification_services from './routes/notification_services-routes';
import * as cron from 'node-cron';
import { getNasaApod } from './jobs/NASA-poller';

dotenv.config();

//interests that update daily 
const dailyPollers = () => {
    getNasaApod(); 
}
    

const app = express();
const PORT = process.env.PORT || 3000;

enum Routes {
    userServices = '/user',
    notificationServices = '/notifications',
}

// Allow requests from your frontend
app.use(cors({
    origin: process.env.LOCAL_HOST || 'http://localhost:3000',
}));
app.use(express.json());

app.get('/', (req, res) => {
    res.send('Hello World!');
});

app.use(Routes.userServices, user_services)
app.use(Routes.notificationServices, notification_services)

app.listen(PORT, async () => {
    await runMigrations(1);
    await seedInterests(1);
    await dailyPollers(); 
    cron.schedule('0 0 * * *', () => {
        dailyPollers();
        }, {
            timezone: "America/Chicago" //might change this 
    });
    console.log('The application is listening '
    + 'on port http://localhost:'+ PORT +'/');
})