import bcrypt from 'bcrypt';
import { User, UserInterests } from '../models/user';
import {
    addUserToDatabase,
    deleteUserFromDatabase,
    getUserForAuth,
    getUserWithID,
    updateUserDeviceIdInDatabase,
    updateUserInDatabase,
    updateUserLocationInDatabase
} from '../repositories/user_queries';
import dotenv from 'dotenv';
import { deleteAllUserInterestsFromDatabase, addUserInterestToDatabase, getUserInterestsFromDatabase, getInterestsByName } from '../repositories/interests_queries';
import { getLatestEventByInterestId } from '../repositories/event_quaries';
import { addNotificationsToDatabase } from '../repositories/notifications_quaries';
import { databaseNotification } from '../models/notifications';
import { createDbConnect } from '../db';

dotenv.config();
const SALT_ROUNDS = process.env.SALT_ROUNDS ? parseInt(process.env.SALT_ROUNDS) : 10;

export const getUserService = async (username: string, password: string) => {
    const database_user = await getUserForAuth(1, username);
    if (!database_user) { 
        console.log(`User "${username}" not found in database.`);
        return null;
    }
    const passwordMatch = await bcrypt.compare(password, database_user.password);
    if (!passwordMatch) {
        return null;
    }
    else {
        const userWithInterests = { ...database_user, interests: [] as UserInterests[] };
        if (database_user) {
            const dbInterests = await getUserInterestsFromDatabase(1, database_user.id);
            userWithInterests.interests = dbInterests;
        }
        return userWithInterests;
    }
}

const normalizeDeviceId = (value?: string | null): string => {
    return (value ?? '').trim();
}

export const linkDeviceToUserService = async (userId: number, deviceId: string): Promise<void> => {
    const normalizedDeviceId = normalizeDeviceId(deviceId);
    if (!normalizedDeviceId) {
        return;
    }

    await updateUserDeviceIdInDatabase(1, userId, normalizedDeviceId);
}

export const getUserAndLinkDeviceService = async (
    username: string,
    password: string,
    deviceId?: string | null
) => {
    const user = await getUserService(username, password);
    if (!user) {
        return null;
    }

    if (deviceId) {
        await linkDeviceToUserService(user.id, deviceId);
    }

    return user;
}

//should never add user with interests
export const addUserService = async (
    username: string,
    email: string | null,
    password: string,
    deviceId?: string | null
) => {
    const normalizedDeviceId = normalizeDeviceId(deviceId);
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    const newUser = await addUserToDatabase(1, username, email, hashedPassword, normalizedDeviceId || null);
    if (!newUser) {
        throw new Error('Failed to create user');
    }

    if (normalizedDeviceId) {
        const welcomeNotification: databaseNotification = {
            user_id: newUser.id,
            notifType: 'welcome',
            from_source: 'podwork',
            notification_data: {
                timestamp: new Date(),
                from_source: 'podwork',
                media: '',
                headline: `Welcome, ${username}!`,
                info: 'your pod is now linked. keep the website open to configure and customize your polypod!',
                seemore: '',
            },
            is_read: false,
            created_at: new Date(),
        };

        await addNotificationsToDatabase(1, [welcomeNotification]);
    }

    return newUser;
}

export const updateUserService = async (userId: number, updatedUserData: Partial<User>) => {
    const existingUser = await getUserWithID(1, userId);
    if (!existingUser) {
        return null;
    }
    if (updatedUserData?.password) {
        updatedUserData.password = await bcrypt.hash(updatedUserData.password, SALT_ROUNDS);
    }
    if (updatedUserData?.username, updatedUserData?.email, updatedUserData?.password) {
        await updateUserInDatabase(1, userId, updatedUserData);
    } 
    if (updatedUserData?.interests) {
        await deleteAllUserInterestsFromDatabase(1, userId);

        let interests : UserInterests[] = [];
        const starterNotifications: databaseNotification[] = [];
        for (const interest of updatedUserData.interests) {
            const interestData = await getInterestsByName(1, interest);
            await addUserInterestToDatabase(1, userId, interestData.id);
            interests.push(interestData);

            // Seed one notification with the latest known event for newly selected interests.
            const latestEvent = await getLatestEventByInterestId(1, interestData.id);
            if (latestEvent) {
                starterNotifications.push({
                    user_id: userId,
                    notifType: 'base',
                    from_source: latestEvent.from_source,
                    notification_data: latestEvent,
                    is_read: false,
                    created_at: new Date(),
                });
            }
        }

        if (starterNotifications.length > 0) {
            await addNotificationsToDatabase(1, starterNotifications);
        }
        
    }
    const updatedUser: User = await getUserWithID(1, userId) as User;
    updatedUser.interests = await getUserInterestsFromDatabase(1, userId);
    return updatedUser;
}

export const deleteUserService = async (userId: number) => {
    const user = await deleteUserFromDatabase(1, userId);
    return user;
}

export const updateUserLocationService = async (userId: number, zipCode: string): Promise<boolean> => {
    const location = await updateUserLocationInDatabase(1, userId, zipCode);
    return location;
}