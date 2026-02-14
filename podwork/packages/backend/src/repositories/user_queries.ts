import { dbPromise } from '../db';
import { user } from '../models/user';


export const findUserByUsername = async (username: string): Promise<user | null> => {
    const db = await dbPromise;

    const row = await db.get(
        `SELECT * FROM users WHERE username = ?`,
        username
    );

    return row ?? null;
};

export const addUserToDatabase = async (username: string, email: string, passwordHash: string): Promise<user | null> => {
    const db = await dbPromise;
    const result = await db.run(
        `INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)`,
        username,
        email,
        passwordHash
    );
    const newUserId = result.lastID;
    const newUser = await db.get(`SELECT * FROM users WHERE id = ?`, newUserId);
    return newUser ?? null;
};

export const updateUserInDatabase = async (userId: number, updatedUserData: Partial<user>): Promise<user | null> => {
    const db = await dbPromise;
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
        fieldsToUpdate.push('password_hash = ?');
        values.push(updatedUserData.password);
    }
    if (fieldsToUpdate.length === 0) {
        return null;
    }
    const updateQuery = `UPDATE users SET ${fieldsToUpdate.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`;
    values.push(userId);
    await db.run(updateQuery, ...values);
    const updatedUser = await db.get(`SELECT * FROM users WHERE id = ?`, userId);
    return updatedUser ?? null;
};

export const deleteUserFromDatabase = async (userId: number): Promise<user | null> => {
    const db = await dbPromise;
    const userToDelete = await db.get(`SELECT * FROM users WHERE id = ?`, userId);
    if (!userToDelete) {
        return null;
    }
    await db.run(`DELETE FROM users WHERE id = ?`, userId);
    return userToDelete;
};