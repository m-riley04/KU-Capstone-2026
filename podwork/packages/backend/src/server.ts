

import express, { Request, Response } from 'express';
import cors from 'cors';
import user_services from './routes/users_services-routes';
import dotenv from 'dotenv';
import { runMigrations } from './db/run_migrations';
import { seedInterests } from './db/seed_interests';

dotenv.config();


const app = express();
const PORT = process.env.PORT || 3000;

enum Routes {
    USER_SERVICES = '/user'
}

// Allow requests from your frontend
app.use(cors({
    origin: process.env.LOCAL_HOST || 'http://localhost:3000',
}));
app.use(express.json());

app.use(Routes.USER_SERVICES, user_services)

app.listen(PORT, async () => {
    await runMigrations();
    await seedInterests();
    console.log('The application is listening '
    + 'on port http://localhost:'+ PORT +'/');
})