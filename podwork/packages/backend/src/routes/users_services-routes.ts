
import express from 'express';
import { addUserRequest, deleteUserRequest, getUserRequest, updateUserRequest } from '../controllers/user_services-controller';

const user_services = express.Router()

// authenticate user service routes
user_services.get('/:username', getUserRequest);
user_services.post('/update', addUserRequest);
user_services.put('/:userId', updateUserRequest);
user_services.delete('/:userId', deleteUserRequest);

//export the user services router
export default user_services;