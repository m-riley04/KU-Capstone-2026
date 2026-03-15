import { Request, Response } from 'express';
import { getInterestService } from '../services/interst-services';

export const getInterestRequest = async (req: Request, res: Response) => {
    const interests = await getInterestService();
    if (!interests) {
        return res.status(404).json({ error: 'Interests not found' });
    }
    return res.status(200).json(interests);
}
        