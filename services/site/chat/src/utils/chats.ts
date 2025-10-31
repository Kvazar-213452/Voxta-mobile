type ChatEntry = {
  chatId: string;
  createdAt: string; // ISO string
  expirationTime: number; // timestamp (ms)
};

let CHATS: ChatEntry[] = [];

/**
 * Додає чат у кеш з часом створення і тривалістю існування.
 */
export function ADD_CHAT(chatId: string, createdAt: string, expirationHours: number) {
  cleanupExpiredChats();

  const exists = CHATS.some(c => c.chatId === chatId);
  if (!exists) {
    const expirationTime = new Date(createdAt).getTime() + expirationHours * 60 * 60 * 1000;
    CHATS.push({ chatId, createdAt, expirationTime });
  }
}

/**
 * Видаляє прострочені чати.
 */
function cleanupExpiredChats() {
  const now = Date.now();
  CHATS = CHATS.filter(chat => chat.expirationTime > now);
}

/**
 * Повертає всі активні чати у форматі ["id1", "id2", ...]
 */
export function GET_CHATS(): string[] {
  cleanupExpiredChats();
  return CHATS.map(chat => chat.chatId);
}