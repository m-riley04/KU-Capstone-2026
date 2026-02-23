import bcrypt from 'bcrypt';
import { User, UserInterests } from '../models/user';
import { addUserToDatabase, deleteUserFromDatabase, getUserFromDatabase, updateUserInDatabase } from '../repositories/user_queries';
import dotenv from 'dotenv';
import { addUserInterestToDatabase, getInterests, getUserInterestsFromDatabase } from '../repositories/interests_queries';

dotenv.config();
const SALT_ROUNDS = process.env.SALT_ROUNDS ? parseInt(process.env.SALT_ROUNDS) : 10;

export const getUserService = async (username: string, password: string) => {
    const database_user = await getUserFromDatabase(1, username);
    if (!database_user) {
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
    if (updatedUserData?.password) {
        updatedUserData.password = await bcrypt.hash(updatedUserData.password, SALT_ROUNDS);
    }
    const user_data = { name : updatedUserData.username, email: updatedUserData.email, password: updatedUserData.password };
    const updatedUser = await updateUserInDatabase(1, userId, user_data);
    if (!updatedUser) {
        return null;
    }
    if (updatedUserData?.interests) {
        for (const interest of updatedUserData.interests) {
            await getInterests(1, interest);
            await addUserInterestToDatabase(1, updatedUser.id, interest.id);
        }
    }
    return updatedUser;
}

export const deleteUserService = async (userId: number) => {
    const user = await deleteUserFromDatabase(1, userId);
    return user;
}
