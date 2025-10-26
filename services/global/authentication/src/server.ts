import express from 'express';
import http from 'http';
import dotenv from 'dotenv';
import publicRouter from './routes/public';
import authRouter from './routes/auth';
import CONFIG from './config';

dotenv.config();

const app = express();
const server = http.createServer(app);

app.use(express.json());

app.use(publicRouter);
app.use(authRouter);

import os from 'os';

server.listen(CONFIG.PORT, '0.0.0.0', () => {
  const interfaces = os.networkInterfaces();
  console.log('Server is running and available at:');
  
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) {
        console.log(`http://${iface.address}:${CONFIG.PORT}`);
      }
    }
  }
});
