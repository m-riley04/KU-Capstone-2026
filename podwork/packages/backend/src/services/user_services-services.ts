import bcrypt from 'bcrypt';
import { addUserToDatabase, deleteUserFromDatabase, findUserByUsername, updateUserInDatabase } from '../repositories/user_queries';
import { user } from '../models/user';
import { dbPromise } from '../db';


const SALT_ROUNDS = 10;

export const getUserService = async (username: string, password: string) => {
    const database_user = await findUserByUsername(username);
    if (!database_user) {
        return null;
    }
    const passwordMatch = await bcrypt.compare(password, database_user.password);
    if (!passwordMatch) {
        return null;
    }
    else {
        return database_user;
    }
}

export const addUserService = async (username: string, email: string, password: string) => {
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    const newUser = await addUserToDatabase(username, email, hashedPassword);
    if (!newUser) {
        throw new Error('Failed to create user');
    }
    return newUser;
}

export const updateUserService = async (userId: number, updatedUserData: Partial<user>) => {
    if (updatedUserData?.password) {
        updatedUserData.password = await bcrypt.hash(updatedUserData.password, SALT_ROUNDS);
    }
    const updatedUser = await updateUserInDatabase(userId, updatedUserData);
    if (!updatedUser) {
        return null;
    }
    return updatedUser;
}

export const deleteUserService = async (userId: number) => {
    const user = await deleteUserFromDatabase(userId);
    return user;
}
