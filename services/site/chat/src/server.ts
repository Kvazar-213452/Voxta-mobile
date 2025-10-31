import express from 'express';
import http from 'http';
import dotenv from 'dotenv';
import router from './router';
import CONFIG from './config';
import os from 'os';
import { initSocketServer } from './socket/socketServer';

dotenv.config();

const app = express();
const server = http.createServer(app);

app.use(express.json());
app.use(router);

initSocketServer(server);

server.listen(CONFIG.PORT, '0.0.0.0', () => {
  const interfaces = os.networkInterfaces();
  console.log('✅ HTTP + Socket.IO сервер запущено та доступний за адресами:');
  
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) {
        console.log(`http://${iface.address}:${CONFIG.PORT}`);
      }
    }
  }
});
