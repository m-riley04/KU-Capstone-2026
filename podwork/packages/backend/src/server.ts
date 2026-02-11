

import express, { Request, Response } from 'express';
import cors from 'cors';

const app = express();
const PORT:Number=3000;

// Allow requests from your frontend
app.use(cors({
    origin: 'http://localhost:3000'
}));

// Handling GET / Request
app.get('/', (req : Request, res: Response) => {
    res.send('Welcome to typescript backend!');
})

// Server setup
app.listen(PORT,() => {
    console.log('The application is listening '
    + 'on port http://localhost:'+ PORT +'/');
})