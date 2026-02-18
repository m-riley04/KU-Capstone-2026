
import express from 'express';
import { addUserRequest, deleteUserRequest, getUserRequest, updateUserRequest } from '../controllers/user_services-controller';

enum path {
    GET_USER = '/:username',
    ADD_USER = '/add',
    UPDATE_USER = '/:userId',
    DELETE_USER = '/:userId'
}

const user_services = express.Router()

// authenticate user service routes
user_services.get(path.GET_USER, getUserRequest);
user_services.post(path.ADD_USER, addUserRequest);
user_services.put(path.UPDATE_USER, updateUserRequest);
user_services.delete(path.DELETE_USER, deleteUserRequest);

//export the user services router
export default user_services;