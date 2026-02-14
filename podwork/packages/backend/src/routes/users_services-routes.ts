
import express from 'express';
import { addUserRequest, deleteUserRequest, getUserRequest, updateUserRequest } from '../controllers/user_services-controller';

const user_services = express.Router()

// authenticate user service routes
user_services.get('/user/:username', getUserRequest);
user_services.post('/users', addUserRequest);
user_services.put('/user/:userId', updateUserRequest);
user_services.delete('/user/:userId', deleteUserRequest);

//export the user services router
export default user_services;