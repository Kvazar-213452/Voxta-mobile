import { getMongoClient } from "../utils/getMongoClient";
import { Db } from "mongodb";

type ChatEntry = {
  chatId: string;
  createdAt: string;       // ISO string
  expirationTime: number;  // timestamp (ms)
};

let CHATS: ChatEntry[] = [];

/**
 * Додає чат у кеш з часом створення і датою видалення (expirationDate — повна ISO дата).
 */
export function ADD_CHAT(chatId: string, createdAt: string, expirationDate: string) {
  cleanupExpiredChats();

  const exists = CHATS.some(c => c.chatId === chatId);
  if (!exists) {
    const expirationTime = new Date(expirationDate).getTime();
    if (isNaN(expirationTime)) {
      console.error(`❌ Некоректна дата видалення: ${expirationDate}`);
      return;
    }

    CHATS.push({ chatId, createdAt, expirationTime });
    console.log(`✅ Додано чат ${chatId} (видалиться о ${expirationDate})`);
  }
}

/**
 * Видаляє прострочені чати.
 */
async function cleanupExpiredChats() {
  const now = Date.now();
  const expired = CHATS.filter(chat => chat.expirationTime <= now);

  for (const chat of expired) {
    await DELETE_CHAT_FROM_DB(chat.chatId);
  }

  CHATS = CHATS.filter(chat => chat.expirationTime > now);
}

/**
 * Видаляє чат з бази даних (chats + users)
 */
async function DELETE_CHAT_FROM_DB(chatId: string) {
  const client = await getMongoClient();

  try {
    const dbChats: Db = client.db("chats");
    const chatCollection = dbChats.collection(chatId);
    const chatConfig = await chatCollection.findOne({ _id: "config" as any });

    if (!chatConfig || !Array.isArray(chatConfig.participants)) {
      console.warn(`⚠️ Чат ${chatId} не має учасників або не знайдено.`);
      return;
    }

    const dbUsers: Db = client.db("users");
    for (const userId of chatConfig.participants) {
      const userCollection = dbUsers.collection(userId);
      const userdata = await userCollection.findOne({ _id: "config" as any });

      if (userdata && Array.isArray(userdata.chats)) {
        const updatedChats = userdata.chats.filter((id: string) => id !== chatId);
        await userCollection.updateOne(
          { _id: "config" as any },
          { $set: { chats: updatedChats } }
        );
      }
    }

    await chatCollection.drop();
    console.log(`🗑️ Чат ${chatId} успішно видалено з DB`);
  } catch (err) {
    console.error(`❌ Помилка при видаленні чату ${chatId}:`, err);
  }
}

/**
 * Повертає всі активні чати у форматі ["id1", "id2", ...]
 */
export function GET_CHATS(): string[] {
  cleanupExpiredChats();
  return CHATS.map(chat => chat.chatId);
}
