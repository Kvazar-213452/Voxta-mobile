import { Server as SocketIOServer } from 'socket.io';
import { getMongoClient } from '../utils/getMongoClient';
import fs from 'fs/promises';
import path from 'path';
import { randomBytes } from 'crypto';
import { GET_CHATS } from '../utils/chats';

let io: any = null;
let CHATS: string[] = [];
const messageCache = new Map<string, any[]>();

// Генерація унікального ID користувача
function generateUserId(): string {
  return randomBytes(8).toString('hex');
}

export function initSocketServer(server: any) {
  io = new SocketIOServer(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"]
    }
  });

  io.on('connection', (socket: any) => {
    // Генеруємо унікальний ID для кожного користувача при підключенні
    const userId = generateUserId();
    socket.userId = userId;

    console.log(`Нове підключення: ${socket.id}, userId: ${userId}`);

    // Відправляємо userId клієнту
    socket.emit('user_id_assigned', { userId });

    // Завантаження інформації про чат
    socket.on('load_chat_info', async (chatId: string) => {
      try {
        if (!GET_CHATS().includes(chatId)) {
          socket.emit('error', { message: 'Чат не знайдено' });
        }

        const client = await getMongoClient();
        const db = client.db("chats");
        const collection = db.collection(chatId);
        const chatConfig = await collection.findOne({ _id: "config" as any });

        if (chatConfig) {
          socket.emit('load_chat', chatConfig);
        } else {
          socket.emit('error', { message: 'Чат не знайдено' });
        }
      } catch (error) {
        console.error('Помилка завантаження інформації чату:', error);
        socket.emit('error', { message: 'Помилка завантаження чату' });
      }
    });

    // Завантаження контенту чату
    socket.on('load_chat_content', async (chatId: string) => {
      try {
        if (!GET_CHATS().includes(chatId)) {
          socket.emit('error', { message: 'Чат не знайдено' });
        }

        let messages = messageCache.get(chatId) || [];

        const chatDataPath = path.join(process.cwd(), 'data', chatId);

        try {
          await fs.access(chatDataPath);
          const files = await fs.readdir(chatDataPath);

          for (const file of files) {
            if (file.endsWith('.json')) {
              const filePath = path.join(chatDataPath, file);
              const fileContent = await fs.readFile(filePath, 'utf-8');
              const fileMessage = JSON.parse(fileContent);

              const existsInCache = messages.some(m => m.id === fileMessage.id);
              if (!existsInCache) {
                messages.push(fileMessage);
              }
            }
          }
        } catch (err) {
          console.log(`Папка ${chatDataPath} не існує або порожня`);
        }

        messages.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());

        messageCache.set(chatId, messages);

        socket.emit('chat_content', { chatId, messages });
      } catch (error) {
        console.error('Помилка завантаження контенту чату:', error);
        socket.emit('error', { message: 'Помилка завантаження контенту' });
      }
    });

    // Обробка повідомлень
    socket.on('message', async (msg: any) => {
      try {
        const { chatId, type, content, userId, username, id, timestamp } = msg;

        if (!GET_CHATS().includes(chatId)) {
          socket.emit('error', { message: 'Чат не знайдено' });
        }

        if (!GET_CHATS().includes(chatId)) {
          socket.emit('error', { message: 'Чат не знайдено в доступних' });
          return;
        }

        const message = {
          id: id || Date.now().toString(),
          chatId,
          type,
          content,
          userId, // Тимчасово зберігаємо для відправки клієнтам
          username,
          timestamp: timestamp || new Date().toISOString()
        };

        // Зберігаємо в кеш
        const chatMessages = messageCache.get(chatId) || [];
        chatMessages.push(message);
        messageCache.set(chatId, chatMessages);

        // Якщо це файл або зображення - зберігаємо БЕЗ userId
        if (type === "file" || type === "img") {
          const chatDataPath = path.join(process.cwd(), 'data', chatId);

          await fs.mkdir(chatDataPath, { recursive: true });

          // Створюємо копію повідомлення БЕЗ userId для збереження
          const messageToSave = {
            id: message.id,
            chatId: message.chatId,
            type: message.type,
            content: message.content,
            username: message.username,
            timestamp: message.timestamp
            // userId НЕ зберігаємо!
          };

          const fileName = `${message.id}.json`;
          const filePath = path.join(chatDataPath, fileName);
          await fs.writeFile(filePath, JSON.stringify(messageToSave, null, 2), 'utf-8');

          console.log(`Файл збережено БЕЗ userId: ${filePath}`);
        }

        // Відправляємо повідомлення всім клієнтам (з userId для правильного відображення)
        io.emit('new_message', message);

      } catch (error) {
        console.error('Помилка обробки повідомлення:', error);
        socket.emit('error', { message: 'Помилка відправки повідомлення' });
      }
    });

    socket.on('disconnect', () => {
      console.log(`🔴 Клієнт відключився: ${socket.id}, userId: ${userId}`);
    });
  });

  console.log('🚀 Socket.IO сервер ініціалізовано');
  return io;
}

export function getIO() {
  if (!io) throw new Error('Socket.IO сервер ще не ініціалізовано');
  return io;
}

export function getAvailableChats() {
  return CHATS;
}

export function clearMessageCache(chatId?: string) {
  if (chatId) {
    messageCache.delete(chatId);
  } else {
    messageCache.clear();
  }
}