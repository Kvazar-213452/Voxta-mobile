import { Request, Response } from 'express';

export default class Chat {
  async chatGet(req: Request, res: Response): Promise<void> {
    const { data, key, type } = req.body;

    try {
      if (!data || !key || !type) {
        res.status(400).json({ code: 0, error: 'error_params' });
        return;
      }


      res.json({ code: 1 });
    } catch (err) {
      console.error('register Error:', err);
      res.status(500).json({ code: 0, error: 'error_server' });
    }
  }
}