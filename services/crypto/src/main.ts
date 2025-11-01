import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import fs from 'fs';
import { generateKeyPair, encryptMessage, decryptMessage } from './encryptionService';
import { loadConfig, rebuildConfig, CONFIG } from "./config";

const app = express();
const MAX_REQUEST_SIZE = 100 * 1024 * 1024;

app.use(express.json({ limit: `${MAX_REQUEST_SIZE}b` }));
app.use(express.urlencoded({ extended: true, limit: `${MAX_REQUEST_SIZE}b` }));

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use((req: Request, res: Response, next: NextFunction) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

const initializeKeys = () => {
  if (!fs.existsSync('public_key.pem') || !fs.existsSync('private_key.pem')) {
    generateKeyPair();
  } else {
    console.log('Використовуються існуючі ключі');
  }
};

app.get('/public_key_mobile', async (req: Request, res: Response) => {
  try {
    const publicKey = fs.readFileSync('public_key.pem', 'utf-8');
    res.json({ key: publicKey });
  } catch {
    res.status(404).json({ error: 'Публічний ключ не знайдено' });
  }
});

app.post('/encryption', async (req: Request, res: Response) => {
  try {
    const { key: publicKey, data: message } = req.body;

    if (!publicKey || !message)
      return res.status(400).json({ error: 'Відсутні необхідні параметри' });

    if (message.length > 1024 * 1024)
      return res.status(400).json({ error: 'Повідомлення занадто велике' });

    const result = encryptMessage(publicKey, message);

    res.json({ code: 1, message: result });
  } catch (error) {
    const msg = error instanceof Error ? error.message : 'Невідома помилка';
    res.status(400).json({ error: `Помилка шифрування: ${msg}` });
  }
});

app.post('/decrypt', async (req: Request, res: Response) => {
  try {
    const { data } = req.body;
    if (!data?.key || !data?.data)
      return res.status(400).json({ error: 'Відсутні необхідні параметри' });

    const result = decryptMessage({ key: data.key, data: data.data });

    res.json({ code: 1, message: result });
  } catch (error) {
    const msg = error instanceof Error ? error.message : 'Невідома помилка';
    res.status(400).json({ error: `Помилка розшифрування: ${msg}` });
  }
});

app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err.message.includes('request entity too large')) {
    return res.status(400).json({
      error: `Розмір запиту перевищує ${MAX_REQUEST_SIZE / (1024 * 1024)}MB`
    });
  }
  console.error('❌ Помилка сервера:', err);
  res.status(500).json({ error: 'Внутрішня помилка сервера' });
});

async function main() {
  try {
    await loadConfig("GLOBAL_URL");
    await loadConfig("GLOBAL_DB");
    await loadConfig();

    rebuildConfig();
    initializeKeys();

    app.listen(CONFIG.PORT, CONFIG.API, () => {
      console.log(`Сервер запущено на http://${CONFIG.API}:${CONFIG.PORT}`);
      console.log(`Максимальний розмір запиту: ${MAX_REQUEST_SIZE / (1024 * 1024)}MB`);
    });
  } catch (err) {
    console.error("Помилка при старті сервера:", err);
    process.exit(1);
  }
}

main();