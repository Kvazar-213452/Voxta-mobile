import express from 'express';
import http from 'http';
import router from './router';
import { loadConfig, rebuildConfig, CONFIG } from "./config";
import os from 'os';
import { initSocketServer } from './socket/socketServer';

async function main() {
  try {
    // Завантаження конфігурації
    await loadConfig("GLOBAL_URL");
    await loadConfig("GLOBAL_DB");
    await loadConfig();
    rebuildConfig();

    // Створення Express додатку
    const app = express();
    
    // Middleware для обробки JSON
    app.use(express.json({ limit: '50mb' }));
    app.use(express.urlencoded({ extended: true, limit: '50mb' }));

    // CORS для Express (якщо потрібно)
    app.use((req: any, res: any, next) => {
      res.header('Access-Control-Allow-Origin', '*');
      res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      res.header('Access-Control-Allow-Credentials', 'true');
      
      if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
      }
      next();
    });

    // Health check endpoint
    app.get('/health', (req, res) => {
      res.json({ status: 'ok', timestamp: new Date().toISOString() });
    });

    // Підключення маршрутів Express
    app.use(router);

    // Створення HTTP сервера
    const server = http.createServer(app);

    // Ініціалізація Socket.IO на тому ж HTTP сервері
    initSocketServer(server);

    // Запуск сервера
    server.listen(CONFIG.PORT, CONFIG.API, () => {
      const interfaces = os.networkInterfaces();
      console.log('='.repeat(50));
      console.log('🚀 HTTP + Socket.IO сервер успішно запущено!');
      console.log('='.repeat(50));
      console.log('\n📡 Сервер доступний за адресами:');
      
      // Локальна адреса
      console.log(`   - http://localhost:${CONFIG.PORT}`);
      console.log(`   - http://127.0.0.1:${CONFIG.PORT}`);
      
      // Мережеві адреси
      for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name] || []) {
          if (iface.family === 'IPv4' && !iface.internal) {
            console.log(`   - http://${iface.address}:${CONFIG.PORT}`);
          }
        }
      }
      
      console.log('\n✅ Express API: готовий приймати HTTP запити');
      console.log('✅ Socket.IO: готовий приймати WebSocket підключення');
      console.log('='.repeat(50) + '\n');
    });

    // Обробка помилок сервера
    server.on('error', (error: NodeJS.ErrnoException) => {
      if (error.code === 'EADDRINUSE') {
        console.error(`❌ Помилка: Порт ${CONFIG.PORT} вже використовується`);
      } else if (error.code === 'EACCES') {
        console.error(`❌ Помилка: Недостатньо прав для використання порту ${CONFIG.PORT}`);
      } else {
        console.error('❌ Помилка сервера:', error);
      }
      process.exit(1);
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      console.log('\n⚠️  SIGTERM отримано, закриваємо сервер...');
      server.close(() => {
        console.log('✅ Сервер закрито');
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      console.log('\n⚠️  SIGINT отримано, закриваємо сервер...');
      server.close(() => {
        console.log('✅ Сервер закрито');
        process.exit(0);
      });
    });

  } catch (err) {
    console.error("❌ Критична помилка при запуску сервера:", err);
    process.exit(1);
  }
}

main();