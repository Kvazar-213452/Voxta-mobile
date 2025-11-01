import { Request, Response } from 'express';
import { ADD_CHAT } from '../utils/chats';

export default class Chat {
  static async loadChats(req: Request, res: Response): Promise<void> {
    const { chat, createdAt, expirationHours, pasw } = req.body;
    try {
      if (!chat || !createdAt || !expirationHours || !pasw) {
        res.status(400).json({ code: 0, error: 'error_params' });
        return;
      }

      ADD_CHAT(chat, createdAt, expirationHours, pasw);

      res.json({ code: 1 });
    } catch (err) {
      console.error('loadChats Error:', err);
      res.status(500).json({ code: 0, error: 'error_server' });
    }
  }
}