import { Socket } from "socket.io";
import { getMongoClient } from "../../../models/mongoClient";
import { verifyAuth } from "../../../utils/verifyAuth";
import { Db } from "mongodb";

function generateRandomKey(length: number): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let result = "";
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

export function onGenerateKeyChat(socket: Socket): void {
  socket.on("generate_key_chat", async (data: { id: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      const client = await getMongoClient();
      const db: Db = client.db("chats");

      const chatId = data.id;

      try {
        const collection = db.collection<{ _id: string; [key: string]: any }>(chatId);

        const newKey = generateRandomKey(9);

        const result = await collection.updateOne(
          { _id: "config" },
          { $set: { key: newKey } }
        );

        if (result.matchedCount > 0) {
          socket.emit("generate_key_chat", { code: 1, key: newKey });
        } else {
          socket.emit("generate_key_chat", { code: 0, error: "config_not_found" });
        }
      } catch (err) {
        console.error(`DB error for chat ${chatId}:`, err);
        socket.emit("generate_key_chat", { code: 0, error: "db_error" });
      }
    } catch (err) {
      console.error("Unexpected error in generate_key_chat:", err);
      socket.emit("generate_key_chat", { code: 0, error: "internal_error" });
    }
  });
}
