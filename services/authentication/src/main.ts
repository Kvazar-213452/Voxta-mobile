import express, { Express } from 'express';
import http from 'http';
import publicRouter from './routes/public';
import authRouter from './routes/auth';
import { loadConfig, rebuildConfig, CONFIG } from "./config";
import os from 'os';

async function main() {
  await loadConfig("GLOBAL_URL");
  await loadConfig("GLOBAL_DB");
  await loadConfig();

  rebuildConfig();

  const app: Express = express();
  const server = http.createServer(app);

  app.use(express.json());

  app.use(publicRouter);
  app.use(authRouter);

  server.listen(CONFIG.PORT, CONFIG.API, () => {
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
}

main().catch((err) => {
  console.error('Error starting server:', err);
});