import bcrypt from 'bcrypt';
import { addUserToDatabase, deleteUserFromDatabase, getUserFromDatabase, updateUserInDatabase } from '../src/repositories/user_queries';
import { addUserInterestToDatabase, getInterests } from '../src/repositories/interests_queries';
import { addUserService, deleteUserService, getUserService, updateUserService } from '../src/services/user_services-services';

jest.mock('bcrypt');
jest.mock('../src/repositories/user_queries');
jest.mock('../src/repositories/interests_queries');

const mockedBcrypt = bcrypt as jest.Mocked<typeof bcrypt>;
const mockedGetUserFromDatabase = getUserFromDatabase as jest.Mock;
const mockedAddUserToDatabase = addUserToDatabase as jest.Mock;
const mockedUpdateUserInDatabase = updateUserInDatabase as jest.Mock;
const mockedDeleteUserFromDatabase = deleteUserFromDatabase as jest.Mock;
const mockedAddUserInterestToDatabase = addUserInterestToDatabase as jest.Mock;
const mockedGetInterests = getInterests as jest.Mock;

describe('User Services', () => {

    beforeEach(() => {
    jest.clearAllMocks();
    });

  // ===============================
  // getUserService
  // ===============================

    describe('getUserService', () => {

    it('returns user if password matches', async () => {
        const fakeUser = { id: 1, username: 'hannah', password: 'hashed' };

        mockedGetUserFromDatabase.mockResolvedValue(fakeUser);
        mockedBcrypt.compare.mockResolvedValue(true as never);

        const result = await getUserService('hannah', 'password');

        expect(result).toEqual(fakeUser);
        expect(mockedBcrypt.compare).toHaveBeenCalledWith('password', 'hashed');
    });

    it('returns null if user not found', async () => {
        mockedGetUserFromDatabase.mockResolvedValue(null);

        const result = await getUserService('hannah', 'password');

        expect(result).toBeNull();
    });

    it('returns null if password does not match', async () => {
        const fakeUser = { id: 1, username: 'hannah', password: 'hashed' };

        mockedGetUserFromDatabase.mockResolvedValue(fakeUser);
        mockedBcrypt.compare.mockResolvedValue(false as never);

        const result = await getUserService('hannah', 'wrong');

        expect(result).toBeNull();
    });
    });

  // ===============================
  // addUserService
  // ===============================

    describe('addUserService', () => {

    it('creates user without interests', async () => {
        const fakeUser = { id: 1, username: 'hannah', email: 'test@test.com' };

        mockedBcrypt.hash.mockResolvedValue('hashedPassword' as never);
        mockedAddUserToDatabase.mockResolvedValue(fakeUser);

        const result = await addUserService(
        'hannah',
        'test@test.com',
        'password'
        );

        expect(mockedBcrypt.hash).toHaveBeenCalled();
        expect(result).toEqual({ ...fakeUser, interests: [] });
    });

    it('creates user with interests', async () => {
        const fakeUser = { id: 1, username: 'hannah', email: 'test@test.com' };
        const interests = [{ id: 1 }, { id: 2 }];

        mockedBcrypt.hash.mockResolvedValue('hashedPassword' as never);
        mockedAddUserToDatabase.mockResolvedValue(fakeUser);
        mockedGetInterests.mockResolvedValue({});
        mockedAddUserInterestToDatabase.mockResolvedValue({});

        const result = await addUserService(
        'hannah',
        'test@test.com',
        'password',
        interests as any
        );

        expect(mockedAddUserInterestToDatabase).toHaveBeenCalledTimes(2);
        expect(result).toEqual({ ...fakeUser, interests });
    });

    it('throws if user creation fails', async () => {
        mockedBcrypt.hash.mockResolvedValue('hashedPassword' as never);
        mockedAddUserToDatabase.mockResolvedValue(null);

        await expect(
        addUserService('hannah', 'test@test.com', 'password')
        ).rejects.toThrow('Failed to create user');
    });
    });

  // ===============================
  // updateUserService
  // ===============================

    describe('updateUserService', () => {

    it('updates user and hashes password if provided', async () => {
        mockedBcrypt.hash.mockResolvedValue('newHashed' as never);
        mockedUpdateUserInDatabase.mockResolvedValue({ id: 1 });

        const result = await updateUserService(1, {
        username: 'newName',
        password: 'newPassword'
        });

        expect(mockedBcrypt.hash).toHaveBeenCalled();
        expect(result).toEqual({ id: 1 });
    });

    it('adds interests if provided', async () => {
        mockedUpdateUserInDatabase.mockResolvedValue({ id: 1 });
        mockedGetInterests.mockResolvedValue({});
        mockedAddUserInterestToDatabase.mockResolvedValue({});

        const interests = [{ id: 1 }, { id: 2 }];

        await updateUserService(1, { interests } as any);

        expect(mockedAddUserInterestToDatabase).toHaveBeenCalledTimes(2);
    });

    it('returns null if update fails', async () => {
        mockedUpdateUserInDatabase.mockResolvedValue(null);

        const result = await updateUserService(1, { username: 'test' });

        expect(result).toBeNull();
    });
    });

  // ===============================
  // deleteUserService
  // ===============================

    describe('deleteUserService', () => {

    it('deletes user successfully', async () => {
        const fakeUser = { id: 1 };

        mockedDeleteUserFromDatabase.mockResolvedValue(fakeUser);

        const result = await deleteUserService(1);

        expect(result).toEqual(fakeUser);
        expect(mockedDeleteUserFromDatabase).toHaveBeenCalledWith(1, 1);
    });
    });
});
