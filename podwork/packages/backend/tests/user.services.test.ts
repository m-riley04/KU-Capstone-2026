import bcrypt from 'bcrypt';
import { addUserToDatabase, deleteUserFromDatabase, getUserFromDatabase, updateUserInDatabase } from '../src/repositories/user_queries';
import { user } from '../src/models/user';
import { addUserService, deleteUserService, getUserService, updateUserService } from '../src/services/user_services-services';

jest.mock('bcrypt');
jest.mock('../src/repositories/user_queries');

describe('UserService', () => {
    const mockUser: Partial<user> = {
        id: 1,
        username: 'testuser',
        email: 'testuser@example.com',
        password: 'hashedpassword',
    };

    test('getUserService should return user if password matches', async () => {
        (getUserFromDatabase as jest.Mock).mockResolvedValue(mockUser);
        (bcrypt.compare as jest.Mock).mockResolvedValue(true);

        const foundUser = await getUserService('testuser', 'password123');
        expect(foundUser).not.toBeNull();
        if (foundUser) {
            expect(foundUser.username).toBe('testuser');
            expect(foundUser.email).toBe('testuser@example.com');
            expect(foundUser.password).toBe('hashedpassword');
        }
    });

    test('getUserService should return null if user does not exist', async () => {
        (getUserFromDatabase as jest.Mock).mockResolvedValue(null);

        const result = await getUserService('unknownuser', 'password123');
        expect(result).toBeNull();
    });

    test('getUserService should return null if password is incorrect', async () => {
        (getUserFromDatabase as jest.Mock).mockResolvedValue(mockUser);
        (bcrypt.compare as jest.Mock).mockResolvedValue(false);

        const result = await getUserService('testuser', 'wrongpassword');
        expect(result).toBeNull();
    });

    test('addUserService should hash password and add user', async () => {
        (bcrypt.hash as jest.Mock).mockResolvedValue('hashedpassword');
        (addUserToDatabase as jest.Mock).mockResolvedValue(mockUser);

        const newUser = await addUserService('testuser', 'testuser@example.com', 'password123');
        expect(newUser).not.toBeNull();
        if (newUser) {
            expect(newUser.username).toBe('testuser');
            expect(newUser.email).toBe('testuser@example.com');
            expect(newUser.password).toBe('hashedpassword');
        }
    });

    test('addUserService should throw error if user creation fails', async () => {
        (bcrypt.hash as jest.Mock).mockResolvedValue('hashedpassword');
        (addUserToDatabase as jest.Mock).mockResolvedValue(null);

        await expect(addUserService('testuser', 'testuser@example.com', 'password123')).rejects.toThrow('Failed to create user');
    });

    test('updateUserService should hash password if provided and update user', async () => {
        const updatedUser = { ...mockUser, password: 'newhashedpassword' };
        (bcrypt.hash as jest.Mock).mockResolvedValue('newhashedpassword');
        (updateUserInDatabase as jest.Mock).mockResolvedValue(updatedUser);

        const result = await updateUserService(1, { password: 'newpassword' });
        expect(result).not.toBeNull();
        if (result) {
            expect(result.password).toBe('newhashedpassword');
        }
    });

    test('updateUserService should update user without hashing if password not provided', async () => {
        const updatedUser = { ...mockUser, email: 'new@example.com' };
        (updateUserInDatabase as jest.Mock).mockResolvedValue(updatedUser);

        const result = await updateUserService(1, { email: 'new@example.com' });
        expect(result).not.toBeNull();
        if (result) {
            expect(result.email).toBe('new@example.com');
        }
    });

    test('updateUserService should return null if update fails', async () => {
        (updateUserInDatabase as jest.Mock).mockResolvedValue(null);

        const result = await updateUserService(1, { email: 'new@example.com' });
        expect(result).toBeNull();
    });

    test('deleteUserService should delete user and return deleted user', async () => {
        (deleteUserFromDatabase as jest.Mock).mockResolvedValue(mockUser);

        const deletedUser = await deleteUserService(1);
        expect(deletedUser).not.toBeNull();
        if (deletedUser) {
            expect(deletedUser.id).toBe(1);
            expect(deletedUser.username).toBe('testuser');
        }
    });
});
