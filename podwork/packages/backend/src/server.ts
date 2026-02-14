

import express, { Request, Response } from 'express';
import cors from 'cors';
import user_services from './routes/users_services-routes';

const app = express();
const PORT:Number=3000;

// Allow requests from your frontend
app.use(cors({
    origin: 'http://localhost:3000'
}));
app.use(express.json());

app.use('/user', user_services)


// Handling GET / Request
app.get('/', (req : Request, res: Response) => {
    res.send('Welcome to typescript backend!');
})

// Server setup
app.listen(PORT,() => {
    console.log('The application is listening '
    + 'on port http://localhost:'+ PORT +'/');
})