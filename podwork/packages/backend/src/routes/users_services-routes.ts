
import express from 'express';
import { addUserRequest, deleteUserRequest, getUserRequest, updateUserRequest } from '../controllers/user_services-controller';

enum path {
    GetUser  = '/:username',
    AddUser = '/add',
    UpdateUser = '/:userId',
    DeleteUser = '/:userId'
}

const user_services = express.Router()

// authenticate user service routes
user_services.get(path.GetUser, getUserRequest);
user_services.post(path.AddUser, addUserRequest);
user_services.put(path.UpdateUser, updateUserRequest);
user_services.delete(path.DeleteUser, deleteUserRequest);

//export the user services router
export default user_services;