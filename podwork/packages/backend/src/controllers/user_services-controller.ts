
import { Request, Response } from 'express';
import { addUserService, deleteUserService, getUserService, updateUserService } from '../services/user_services-services';

export const getUserRequest = async (req: Request, res: Response) => {
    const { username } = req.params as { username: string };
    const userPassword = req.headers['x-password'];
    if (!userPassword || !username) {
        return res.status(400).json({ error: 'Username and password are required' });
    }
    try {
        const user = await getUserService(username, userPassword as string);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        return res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
}};

export const addUserRequest = async (req: Request, res: Response) => {
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
        return res.status(400).json({ error: 'Username, email, and password are required' });
    }
    try {
        const newUser = await addUserService(username, email, password);
        return res.status(201).json(newUser);
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
}

export const updateUserRequest = async (req: Request, res: Response) => {
    if (!req.params.userId || Array.isArray(req.params.userId)) {
        return res.status(400).json({ error: 'Valid User ID is required' });
    }
    const userId = parseInt(req.params.userId);
    const { updated_user } = req.body;
    if (!updated_user) {
        return res.status(400).json({ error: 'Updated user data is required' });
    }
    try {
        const updatedUser = await updateUserService(userId, updated_user);
        if (!updatedUser) {
            return res.status(404).json({ error: 'User not found' });
        }
        return res.status(200).json(updatedUser);
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
}

export const deleteUserRequest = async (req: Request, res: Response) => { 
    if (!req.params.userId || Array.isArray(req.params.userId)) {
        return res.status(400).json({ error: 'Valid User ID is required' });
    }
    try {
        const userId = parseInt(req.params.userId);
        const user = await deleteUserService(userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        return res.status(200).json({ message: 'User deleted successfully' });  
    }catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
}
    
