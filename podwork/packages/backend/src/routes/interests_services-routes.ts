import express from 'express';
import { getInterestRequest } from '../controllers/interests_services-controller';

enum path {
    getInterest = '/',
}

const interests_services = express.Router()

interests_services.get(path.getInterest, getInterestRequest)

export default interests_services;