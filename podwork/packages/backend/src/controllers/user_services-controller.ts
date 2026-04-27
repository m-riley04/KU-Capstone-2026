
import { Request, Response } from 'express';
import { addUserService, deleteUserService, getUserAndLinkDeviceService, updateUserLocationService, updateUserService } from '../services/user_services-services';
import { createDbConnect } from '../db';

const readDeviceId = (req: Request): string => {
    const fromBody = req.body?.deviceId ?? req.body?.deviceid ?? req.body?.userid;
    const fromQuery = req.query?.deviceId ?? req.query?.deviceid ?? req.query?.userid;
    const fromHeader = req.headers['x-device-id'];

    const value = [fromBody, fromQuery, fromHeader].find(candidate => typeof candidate === 'string') as string | undefined;
    return (value ?? '').trim();
}

export const getUserRequest = async (req: Request, res: Response) => {
    const { username } = req.params as { username: string };
    const userPassword = req.headers['x-password'];
    if (!userPassword || !username) {
        return res.status(400).json({ error: 'Username and password are required' });
    }
    try {
        const user = await getUserAndLinkDeviceService(username, userPassword as string, readDeviceId(req));
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        return res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
}};

export const addUserRequest = async (req: Request, res: Response) => {
    const { username, email, password } = req.body;
    if (!username || !password) {
        return res.status(400).json({ error: 'Username and password are required' });
    }
    try {
        const newUser = await addUserService(username, email, password, readDeviceId(req));
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


export const updateUserLocationRequest = async (req: Request, res: Response) => {
    const userIdString = req.params.userId as string; 
    const userId = parseInt(userIdString, 10);

    const { zip_code } = req.body;

    if (!zip_code) {
        return res.status(400).json({ error: "zip_code is required" });
    }

    try {
        const isUpdated = await updateUserLocationService(userId, zip_code);

        if (!isUpdated) {
            return res.status(404).json({ error: "User not found" });
        }

        return res.status(200).json({ 
            message: "Location successfully updated", 
            zip_code: zip_code 
        });

    } catch (error) {
        console.error("Error in updateUserLocationRequest:", error);
        return res.status(500).json({ error: "Internal server error" });
    }
};
    
