import { Request, Response } from 'express';
import * as userServices from '../src/services/user_services-services';
import { getUserRequest, addUserRequest, updateUserRequest, deleteUserRequest } from '../src/controllers/user_services-controller';

jest.mock('../src/services/user_services-services');

describe('UserController', () => {
    const mockUser = {
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        password: 'hashedpassword',
    };

    const mockResponse = () => {
        const res: Partial<Response> = {};
        res.status = jest.fn().mockReturnValue(res);
        res.json = jest.fn().mockReturnValue(res);
        return res as Response;
    };

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('getUserRequest', () => {
        test('should return 400 if username or password missing', async () => {
            const req = { params: {}, headers: {} } as unknown as Request;
            const res = mockResponse();
            await getUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({ error: 'Username and password are required' });
        });

        test('should return 404 if user not found', async () => {
            (userServices.getUserService as jest.Mock).mockResolvedValue(null);
            const req = { params: { username: 'testuser' }, headers: { 'x-password': 'password123' } } as unknown as Request;
            const res = mockResponse();
            await getUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({ error: 'User not found' });
        });

        test('should return 200 with user if found', async () => {
            (userServices.getUserService as jest.Mock).mockResolvedValue(mockUser);
            const req = { params: { username: 'testuser' }, headers: { 'x-password': 'password123' } } as unknown as Request;
            const res = mockResponse();
            await getUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith(mockUser);
        });
    });

    describe('addUserRequest', () => {
        test('should return 400 if required fields missing', async () => {
            const req = { body: {} } as Request;
            const res = mockResponse();
            await addUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({ error: 'Username, email, and password are required' });
        });

        test('should return 201 with new user', async () => {
            (userServices.addUserService as jest.Mock).mockResolvedValue(mockUser);
            const req = { body: { username: 'testuser', email: 'test@example.com', password: 'password123' } } as Request;
            const res = mockResponse();
            await addUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith(mockUser);
        });
    });

    describe('updateUserRequest', () => {
        test('should return 400 if userId missing or updated_user missing', async () => {
            const req1 = { params: {}, body: {} } as unknown as Request;
            const res1 = mockResponse();
            await updateUserRequest(req1, res1);
            expect(res1.status).toHaveBeenCalledWith(400);

            const req2 = { params: { userId: '1' }, body: {} } as unknown as Request;
            const res2 = mockResponse();
            await updateUserRequest(req2, res2);
            expect(res2.status).toHaveBeenCalledWith(400);
        });

        test('should return 404 if update fails', async () => {
            (userServices.updateUserService as jest.Mock).mockResolvedValue(null);
            const req = { params: { userId: '1' }, body: { updated_user: { username: 'newuser' } } } as unknown as Request;
            const res = mockResponse();
            await updateUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({ error: 'User not found' });
        });

        test('should return 200 with updated user', async () => {
            const updatedUser = { ...mockUser, username: 'newuser' };
            (userServices.updateUserService as jest.Mock).mockResolvedValue(updatedUser);
            const req = { params: { userId: '1' }, body: { updated_user: { username: 'newuser' } } } as unknown as Request;
            const res = mockResponse();
            await updateUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith(updatedUser);
        });
    });

    describe('deleteUserRequest', () => {
        test('should return 400 if userId invalid', async () => {
            const req = { params: {} } as unknown as Request;
            const res = mockResponse();
            await deleteUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({ error: 'Valid User ID is required' });
        });

        test('should return 404 if user not found', async () => {
            (userServices.deleteUserService as jest.Mock).mockResolvedValue(null);
            const req = { params: { userId: '1' } } as unknown as Request;
            const res = mockResponse();
            await deleteUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({ error: 'User not found' });
        });

        test('should return 200 if user deleted successfully', async () => {
            (userServices.deleteUserService as jest.Mock).mockResolvedValue(mockUser);
            const req = { params: { userId: '1' } } as unknown as Request;
            const res = mockResponse();
            await deleteUserRequest(req, res);
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({ message: 'User deleted successfully' });
        });
    });
});
