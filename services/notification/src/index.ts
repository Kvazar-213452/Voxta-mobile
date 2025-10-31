import express, { Express, Request, Response } from 'express';
import dotenv from 'dotenv';
import { send_gmail } from './head_com/gmail';

type ResponseData = string | number | object;

dotenv.config();

const app: Express = express();
app.use(express.json());

if (!process.env.VERSION) {
    throw new Error('Missing VERSION in environment variables.');
}

app.post('/send_gmail', async (req: Request, res: Response<ResponseData>) => {
    try {
        const data = req.body.data;

        await send_gmail(data[1].toString(), data[0]);

        res.json({ status: 1 });
    } catch (error) {
        console.error(error);
        res.json({ status: 2 });
    }
});

app.listen(process.env.PORT, () => {
    console.log(`Server running on port ${process.env.PORT}`);
});
