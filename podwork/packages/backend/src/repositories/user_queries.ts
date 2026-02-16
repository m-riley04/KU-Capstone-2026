import { connectionType, createDbConnect, } from '../db';
import { User } from '../models/user';


export const getUserFromDatabase = async (connection: connectionType, username: string): Promise<User | null> => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    const user = await db.get(
        `SELECT * FROM users WHERE username = ?`,
        username
    );
    return user ?? null;
};

export const addUserToDatabase = async (connection: connectionType, username: string, email: string, password: string): Promise<User| null> => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    try {
        const result = await db.run(
            `INSERT INTO users (username, email, password) VALUES (?, ?, ?)`,
            username,
            email,
            password
        );
        console.log('Insert result:', result);
        const newUserId = result.lastID;
        const newUser = await db.get(`SELECT * FROM users WHERE id = ?`, newUserId);
        console.log('New user:', newUser);
        await db.close();
        return newUser ?? null;
    } catch (error: any) {
        if (error.code === 'SQLITE_CONSTRAINT' && error.message.includes('username')) {
            await db.close();
            throw new Error('Username already exists');
        }
        if (error.code === 'SQLITE_CONSTRAINT' && error.message.includes('email')) {
            await db.close();
            throw new Error('Email already exists');
        }
        await db.close();
        throw error;
    }
};

export const updateUserInDatabase = async (connection: connectionType, userId: number, updatedUserData: Partial<User>): Promise<User | null> => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    const fieldsToUpdate = [];
    const values = [];
    if (updatedUserData.username) {
        fieldsToUpdate.push('username = ?');
        values.push(updatedUserData.username);
    }
    if (updatedUserData.email) {
        fieldsToUpdate.push('email = ?');
        values.push(updatedUserData.email);
    }
    if (updatedUserData.password) {
        fieldsToUpdate.push('password = ?');
        values.push(updatedUserData.password);
    }
    if (fieldsToUpdate.length === 0) {
        await db.close();
        return null;
    }
    const updateQuery = `UPDATE users SET ${fieldsToUpdate.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`;
    values.push(userId);
    await db.run(updateQuery, ...values);
    const updatedUser = await db.get(`SELECT * FROM users WHERE id = ?`, userId);
    await db.close();
    return updatedUser ?? null;
};

export const deleteUserFromDatabase = async (connection: connectionType, userId: number): Promise<User | null> => {
    const db = await createDbConnect(connection);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    const userToDelete = await db.get(`SELECT * FROM users WHERE id = ?`, userId);
    if (!userToDelete) {
        await db.close();
        return null;
    }
    await db.run(`DELETE FROM users WHERE id = ?`, userId);
    await db.close();
    return userToDelete;
};