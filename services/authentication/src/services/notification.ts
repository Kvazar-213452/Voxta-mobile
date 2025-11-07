import { Request, Response } from 'express';
import { send_gmail } from '../utils/gmail';

export class Notification {
  static async sendGmail(req: Request, res: Response): Promise<void> {
      try {
        const { data } = req.body;
        await send_gmail(data[1].toString(), data[0]);
        res.json({ status: 1 });
      } catch (error) {
        console.error(error);
        res.status(500).json({ status: 2 });
      }
  }
}