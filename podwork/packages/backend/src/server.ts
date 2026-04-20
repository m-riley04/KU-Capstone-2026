import express, { Request, Response } from 'express';
import cors from 'cors';
import  https  from 'https';
import fs from 'fs';
import user_services from './routes/users_services-routes';
import dotenv from 'dotenv';
import { runMigrations } from './db/run_migrations';
import { seedInterests } from './db/seed_interests';
import notification_services from './routes/notification_services-routes';
import * as cron from 'node-cron';
import { getNasaApod } from './jobs/NASA-poller';
import { getEspnMensCollegeBasketballScoreboard, getEspnMLBScoreboard } from './jobs/ESPN-poller';
import interests_services from './routes/interests_services-routes';
import { getWeatherUpdates } from './jobs/weather-poller';
import path from 'path';

dotenv.config();

// interests that update daily
const dailyPollers = async () => {
    await getNasaApod();
}

// interests that update frequently
const frequentPollers = async () => {
    await getEspnMensCollegeBasketballScoreboard();
    await getEspnMLBScoreboard();
    await getWeatherUpdates();
}
    

const app = express();
const PORT = Number(process.env.PORT) || 3000;

const options = {
    key: fs.readFileSync(path.join(__dirname, '../../../../../../../etc/letsencrypt/live/polypod.net/privkey.pem')),
    cert: fs.readFileSync(path.join(__dirname, '../../../../../../../../etc/letsencrypt/live/polypod.net/fullchain.pem')),
};


enum Routes {
    userServices = '/user',
    notificationServices = '/notifications',
    interestsServices = '/interests'
}

// Allow requests from your frontend
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
    res.send('Hello World!');
});

app.use(Routes.userServices, user_services)
app.use(Routes.notificationServices, notification_services)
app.use(Routes.interestsServices, interests_services)

https.createServer(options, app,).listen(PORT, async () => {
    await runMigrations(1);
    await seedInterests(1);

    // Run pollers once at startup so devices have fresh data immediately.
    await dailyPollers();
    await frequentPollers();

    cron.schedule('0 0 * * *', () => {
        void dailyPollers();
        }, {
            timezone: "America/Chicago" //might change this 
    });

    cron.schedule('*/10 * * * * *', () => {
        void frequentPollers();
        }, {
            timezone: "America/Chicago"
    });

    console.log('The application is listening '
    + 'on port https://www.polypod.net:'+ PORT +'/');
})