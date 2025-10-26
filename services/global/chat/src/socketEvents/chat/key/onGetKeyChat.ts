import { Socket } from "socket.io";
import { getMongoClient } from "../../../models/mongoClient";
import { verifyAuth } from "../../../utils/verifyAuth";
import { Db } from "mongodb";

export function onGetKeyChat(socket: Socket): void {
  socket.on("get_key_chat", async (data: { id: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      const client = await getMongoClient();
      const db: Db = client.db("chats");

      const chatId = data.id;

      try {
        const collection = db.collection<{ _id: string; [key: string]: any }>(chatId);
        const chatConfig = await collection.findOne({ _id: "config" });

        if (chatConfig) {
          const { _id, ...chatWithoutId } = chatConfig;
          socket.emit("get_key_chat", { code: 1, key: chatWithoutId["key"] });
        } else {
          socket.emit("get_key_chat", { code: 0, error: "config_not_found" });
        }
      } catch (err) {
        console.error(`DB error for chat ${chatId}:`, err);
        socket.emit("get_key_chat", { code: 0, error: "db_error" });
      }
    } catch (err) {
      console.error("Unexpected error in get_key_chat:", err);
      socket.emit("get_key_chat", { code: 0, error: "internal_error" });
    }
  });
}
