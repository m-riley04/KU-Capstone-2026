

import express, { Request, Response } from 'express';
import cors from 'cors';
import user_services from './routes/users_services-routes';
import dotenv from 'dotenv';

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


// Handling GET / Request
app.get('/', (req : Request, res: Response) => {
    res.send('Welcome to typescript backend!');
})

// Server setup
app.listen(PORT,() => {
    console.log('The application is listening '
    + 'on port http://localhost:'+ PORT +'/');
})