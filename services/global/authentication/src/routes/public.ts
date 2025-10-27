import express, { Request, Response } from 'express';
import axios from 'axios';

const router = express.Router();

router.get('/public_key_mobile', async (_req: Request, res: Response) => {
    try {
        const response: any = await axios.get(`http://192.168.68.101:3000/public_key_mobile`);
        res.send(response.data.key);
    } catch (error) {
        console.error('Error fetching public_key_mobile:', error);
        res.status(500).send('Failed to fetch public key for mobile');
    }
});

export default router;