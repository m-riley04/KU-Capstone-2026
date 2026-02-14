import { Database } from "sqlite";
import { createDbConnect } from "../src/db";
import { addUserToDatabase, deleteUserFromDatabase, getUserFromDatabase, updateUserInDatabase } from "../src/repositories/user_queries";
import { get } from "node:http";


describe ('UserRepository', () => {
    let db: Database | null | undefined = null;

    
    test('addUser should add a user and return the new user', async () => {
        const newUser = await addUserToDatabase(0, 'testuser', 'testuser@example.com', 'password123');
        expect(newUser).not.toBeNull();
        if (newUser) {
        expect(newUser).toHaveProperty('id');
        expect(newUser.username).toBe('testuser');
        expect(newUser.email).toBe('testuser@example.com');
        expect(newUser.password).toBe('password123');
        expect(newUser).toHaveProperty('created_at');
        expect(newUser).toHaveProperty('updated_at');
        }
    })
    test('addUser should not add a user with duplicate username', async () => {
        await expect(
            addUserToDatabase(0, 'testuser', 'two@example.com', 'password')
        ).rejects.toThrow('Username already exists');
    });
    test('addUser should not add a user with duplicate email', async () => {
        await expect(
            addUserToDatabase(0, 'testuser3', 'testuser@example.com', 'password123')
        ).rejects.toThrow('Email already exists');
    });
    test('getUser should return user data for existing user', async () => {
        const foundUser = await getUserFromDatabase(0, 'testuser');
        expect(foundUser).not.toBeNull();
        if (foundUser) {
            expect(foundUser.username).toBe('testuser');
            expect(foundUser.email).toBe('testuser@example.com');
            expect(foundUser.password).toBe('password123');
        }
    });
    test('updateUser should update user data and return the updated user', async () => {
        const oldUser = await getUserFromDatabase(0, 'testuser');
        if (!oldUser) {
            throw new Error('Failed to get user for update test');
        }
        const updatedUser = await updateUserInDatabase(0, oldUser.id, { username: 'updatedUser' });
        expect(updatedUser).not.toBeNull();
        if (updatedUser) {
            expect(updatedUser.username).toBe('updatedUser');
        }
    });
    test('updateUser should return null if user does not exist', async () => {
        const result = await updateUserInDatabase(0, 9999, { username: 'nonExistentUser' });
        expect(result).toBeNull();
    });
    test('deleteUser should return null for non-existing user', async () => {
        const result = await deleteUserFromDatabase(0, 9999);
        expect(result).toBeNull();
    });
    test('deleteUser should delete the user and return the deleted user', async () => {
        const user = await getUserFromDatabase(0, 'updatedUser');
        if (!user) {
            throw new Error('Failed to get user for delete test');
        }
        const deletedUser = await deleteUserFromDatabase(0, user.id);
        expect(deletedUser).not.toBeNull();
        if (deletedUser) {
            expect(deletedUser.id).toBe(user.id);
            expect(deletedUser.username).toBe(user.username);
            expect(deletedUser.email).toBe(user.email);
            expect(deletedUser.password).toBe(user.password);
        }
        const foundUser = await getUserFromDatabase(0, 'updatedUser');
        expect(foundUser).toBeNull();
    });
});



