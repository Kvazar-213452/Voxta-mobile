import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { verifyAuth } from "../../utils/verifyAuth";
import { Db } from "mongodb";

export function onGetInfoChatFix(socket: Socket): void {
  socket.on("get_info_chat_fix", async (data: { chatId: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;


      const client = await getMongoClient();
      const db: Db = client.db("chats");

      const chatId = data.chatId;

      try {
        const collection = db.collection<{ _id: string;[key: string]: any }>(chatId);
        const chatConfig = await collection.findOne({ _id: "config" });

        if (chatConfig) {
          const { _id, ...chatWithoutId } = chatConfig;
          socket.emit("get_info_chat_fix_return", { code: 1, chat: chatWithoutId });
        } else {
          socket.emit("get_info_chat_fix_return", { code: 0, error: "config_not_found" });
        }
      } catch (err) {
        console.error(`DB error for chat ${chatId}:`, err);
        socket.emit("get_info_chat_fix_return", { code: 0, error: "db_error" });
      }

    } catch (error) {
      socket.emit("get_info_chat_fix_return", { code: 0, error: "server_error" });
    }
  });
}
