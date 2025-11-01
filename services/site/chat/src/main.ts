import express from 'express';
import http from 'http';
import router from './router';
import { loadConfig, rebuildConfig, CONFIG } from "./config";
import os from 'os';
import { initSocketServer } from './socket/socketServer';

async function main() {
  await loadConfig("GLOBAL_URL");
  await loadConfig("GLOBAL_DB");
  await loadConfig();

  rebuildConfig();

  const app = express();
  const server = http.createServer(app);

  app.use(express.json());
  app.use(router);

  initSocketServer(server);

  server.listen(CONFIG.PORT, CONFIG.API, () => {
    const interfaces = os.networkInterfaces();
    console.log('HTTP + Socket.IO сервер запущено та доступний за адресами:');
    
    for (const name of Object.keys(interfaces)) {
      for (const iface of interfaces[name] || []) {
        if (iface.family === 'IPv4' && !iface.internal) {
          console.log(`http://${iface.address}:${CONFIG.PORT}`);
        }
      }
    }
  });
}

main().catch((err) => {
  console.error("Помилка при запуску сервера:", err);
});
