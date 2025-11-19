import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import fs from 'fs';
import {
  generateKeyPair,
  encryptMessage,
  decryptMessage,
  generateKeyPairForServer,
  decryptMessageServer
} from './encryptionService';
import { loadConfig, rebuildConfig, CONFIG } from './config';

const app = express();
const MAX_REQUEST_SIZE = 100 * 1024 * 1024;

app.use(express.json({ limit: `${MAX_REQUEST_SIZE}b` }));
app.use(express.urlencoded({ extended: true, limit: `${MAX_REQUEST_SIZE}b` }));

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use((req: Request, _res: Response, next: NextFunction) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

const initializeKeys = () => {
  if (!fs.existsSync('public_key.pem') || !fs.existsSync('private_key.pem')) {
    console.log('Генерую нові ключі...');
    generateKeyPair();
  } else {
    console.log('Використовуються існуючі ключі');
  }
};

const asyncHandler = (fn: Function) => (req: Request, res: Response, next: NextFunction) =>
  Promise.resolve(fn(req, res, next)).catch(next);

app.get('/public_key_mobile', asyncHandler(async (_req, res) => {
  if (!fs.existsSync('public_key.pem')) {
    return res.status(404).json({ error: 'Публічний ключ не знайдено' });
  }
  const publicKey = fs.readFileSync('public_key.pem', 'utf-8');
  res.json({ key: publicKey });
}));

app.post('/encryption', asyncHandler(async (req: Request, res: Response) => {
  const { key: publicKey, data: message } = req.body;
  if (!publicKey || !message) {
    return res.status(400).json({ error: 'Відсутні необхідні параметри' });
  }
  if (message.length > 1024 * 1024) {
    return res.status(400).json({ error: 'Повідомлення занадто велике' });
  }
  const encrypted = encryptMessage(publicKey, message);
  res.json({ code: 1, message: encrypted });
}));

app.post('/decrypt', asyncHandler(async (req: Request, res: Response) => {
  const { data } = req.body;
  if (!data?.key || !data?.data) {
    return res.status(400).json({ error: 'Відсутні необхідні параметри' });
  }
  const decrypted = decryptMessage({ key: data.key, data: data.data });
  res.json({ code: 1, message: decrypted });
}));

app.post('/generate', asyncHandler(async (_req, res) => {
  const keys = generateKeyPairForServer();
  res.json({ code: 1, result: keys });
}));

app.post('/decrypt_message_server', asyncHandler(async (req: Request, res: Response) => {
  const { data, privateKeyPem } = req.body;
  if (!data?.key || !data?.data) {
    return res.status(400).json({ error: 'Відсутні необхідні параметри' });
  }
  const decrypted = decryptMessageServer({ key: data.key, data: data.data }, privateKeyPem);
  res.json({ code: 1, message: decrypted });
}));

app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  if (err.message.includes('request entity too large')) {
    return res.status(400).json({
      error: `Розмір запиту перевищує ${MAX_REQUEST_SIZE / (1024 * 1024)}MB`
    });
  }
  console.error('Помилка сервера:', err);
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
    console.error('Помилка при старті сервера:', err);
    process.exit(1);
  }
}

main();