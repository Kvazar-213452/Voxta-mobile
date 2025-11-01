import express from 'express';
import Chat from './services/chat';

const router = express.Router();

router.post('/set_chat', Chat.loadChats);

export default router;
