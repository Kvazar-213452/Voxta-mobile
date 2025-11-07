import express from 'express';
import { loginHandler } from '../services/login';
import { registerHandler, registerVerificationHandler } from '../services/register';
import { getInfoToJwtHandler } from '../services/getInfoToJwt';
import { Notification } from '../services/notification';

const router = express.Router();

router.post('/login', loginHandler);
router.post('/get_info_to_jwt', getInfoToJwtHandler);
router.post('/register', registerHandler);
router.post('/register_verification', registerVerificationHandler);

// ! notification

router.post('/send_gmail', Notification.sendGmail);

export default router;
