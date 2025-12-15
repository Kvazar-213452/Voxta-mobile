import { Server as SocketIOServer } from 'socket.io';
import { getMongoClient } from '../utils/getMongoClient';
import fs from 'fs/promises';
import path from 'path';
import { randomBytes } from 'crypto';
import { GET_CHATS, CHECK_CHAT_PASSWORD } from '../utils/chats';
import { CONFIG } from "../config";

let io: any = null;
let CHATS: string[] = [];
const messageCache = new Map<string, any[]>();

function generateUserId(): string {
  return randomBytes(8).toString('hex');
}

export function initSocketServer(server: any) {
  io = new SocketIOServer(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
      credentials: true
    },
    transports: ['websocket', 'polling'],
    pingTimeout: 60000,
    pingInterval: 25000,
    allowUpgrades: true,
    connectTimeout: 45000,
    maxHttpBufferSize: 1e8,
    allowEIO3: true,
    serveClient: false
  });

  io.on('connection', (socket: any) => {
    const userId = generateUserId();
    socket.userId = userId;

    socket.emit('user_id_assigned', { userId });

    socket.on('load_chat_info', async (chatId: string, pasw: string) => {
      try {
        const chats = await GET_CHATS();
        if (!chats.includes(chatId)) {
          socket.emit('error', { message: 'Чат не знайдено' });
          return;
        }

        const isPasswordValid = CHECK_CHAT_PASSWORD(chatId, pasw);
        
        if (!isPasswordValid) {
          socket.emit('error', { message: 'Невірний пароль' });
          return;
        }

        const client = await getMongoClient();
        const db = client.db("chats");
        const collection = db.collection(chatId);
        let chatConfig: any = await collection.findOne({ _id: "config" as any });
        
        chatConfig["avatar"] = CONFIG.API_GLOBAL + chatConfig["avatar"];

        if (chatConfig) {
          socket.emit('load_chat', chatConfig);
        } else {
          socket.emit('error', { message: 'Чат не знайдено' });
        }
      } catch (error) {
        socket.emit('error', { message: 'Помилка завантаження чату' });
      }
    });

    socket.on('load_chat_content', async (chatId: string, pasw: string) => {
      try {
        const chats = await GET_CHATS();
        if (!chats.includes(chatId)) {
          socket.emit('error', { message: 'Чат не знайдено' });
          return;
        }

        const isPasswordValid = CHECK_CHAT_PASSWORD(chatId, pasw);
        
        if (!isPasswordValid) {
          socket.emit('error', { message: 'Невірний пароль' });
          return;
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
        socket.emit('error', { message: 'Помилка завантаження контенту' });
      }
    });

    socket.on('message', async (msg: any, pasw: string) => {
      try {
        const { chatId, type, content, userId, username, id, timestamp } = msg;

        console.log(`📨 Нове повідомлення в чат ${chatId} від ${username}, пароль: ${pasw ? '****' : 'відсутній'}`);

        const chats = await GET_CHATS();
        if (!chats.includes(chatId)) {
          socket.emit('error', { message: 'Чат не знайдено' });
          return;
        }

        const isPasswordValid = CHECK_CHAT_PASSWORD(chatId, pasw);
        
        if (!isPasswordValid) {
          socket.emit('error', { message: 'Невірний пароль' });
          return;
        }

        const message = {
          id: id || Date.now().toString(),
          chatId,
          type,
          content,
          userId,
          username,
          timestamp: timestamp || new Date().toISOString()
        };

        const chatMessages = messageCache.get(chatId) || [];
        chatMessages.push(message);
        messageCache.set(chatId, chatMessages);

        if (type === "file" || type === "img") {
          const chatDataPath = path.join(process.cwd(), 'data', chatId);

          await fs.mkdir(chatDataPath, { recursive: true });

          const messageToSave = {
            id: message.id,
            chatId: message.chatId,
            type: message.type,
            content: message.content,
            username: message.username,
            timestamp: message.timestamp
          };

          const fileName = `${message.id}.json`;
          const filePath = path.join(chatDataPath, fileName);
          await fs.writeFile(filePath, JSON.stringify(messageToSave, null, 2), 'utf-8');
        }

        io.emit('new_message', message);

      } catch (error) {
        socket.emit('error', { message: 'Помилка відправки повідомлення' });
      }
    });

    socket.on('error', (error: any) => {
      console.error(`Помилка сокета ${socket.id}:`, error);
    });

    socket.on('disconnect', (reason: string) => {
      console.log(`❌ Клієнт відключився: ${socket.id}, userId: ${userId}, причина: ${reason}`);
    });
  });

  io.engine.on('connection_error', (err: any) => {
    console.error('Помилка з\'єднання Socket.IO:', err);
  });

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