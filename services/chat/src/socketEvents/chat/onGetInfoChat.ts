import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { verifyAuth } from "../../utils/verifyAuth";
import { getChatsServer } from "../../utils/serverChats";
import { Db } from "mongodb";

export function onGetInfoChat(socket: Socket): void {
  socket.on("get_info_chat", async (data: { chatId: string, type: string, typeChat: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      if (data.typeChat === 'server') {
        let chat = getChatsServer([data.chatId]);

        socket.emit("chat_info", { code: 1, chat: chat[Object.keys(chat)[0]], type: data.type });
      } else {
        const client = await getMongoClient();
        const db: Db = client.db("chats");

        const chatId = data.chatId;

        try {
          const collection = db.collection<{ _id: string; [key: string]: any }>(chatId);
          const chatConfig = await collection.findOne({ _id: "config" });
          
          if (chatConfig) {
            const { _id, ...chatWithoutId } = chatConfig;
            socket.emit("chat_info", { code: 1, chat: chatWithoutId, type: data.type });
          } else {
            socket.emit("chat_info", { code: 0, error: "config_not_found", type: data.type });
          }
        } catch (err) {
          console.error(`DB error for chat ${chatId}:`, err);
          socket.emit("chat_info", { code: 0, error: "db_error", type: data.type });
        }
      }
    } catch (error) {
      socket.emit("chat_info", { code: 0, error: "server_error", type: data.type });
    }
  });
}
