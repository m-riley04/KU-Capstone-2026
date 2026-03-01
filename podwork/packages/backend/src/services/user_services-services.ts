import bcrypt from 'bcrypt';
import { User, UserInterests } from '../models/user';
import { addUserToDatabase, deleteUserFromDatabase, getUserForAuth, getUserWithID, updateUserInDatabase } from '../repositories/user_queries';
import dotenv from 'dotenv';
import { addUserInterestToDatabase, getInterests, getUserInterestsFromDatabase } from '../repositories/interests_queries';

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

//should never add user with interests
export const addUserService = async (username: string, email: string, password: string,) => {
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    const newUser = await addUserToDatabase(1, username, email, hashedPassword);
    if (!newUser) {
        throw new Error('Failed to create user');
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
        let interests : UserInterests[] = [];
        for (const interest of updatedUserData.interests) {
            const interestData = await getInterests(1, interest);
            await addUserInterestToDatabase(1, userId, interestData.id);
            interests.push(interestData);
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
