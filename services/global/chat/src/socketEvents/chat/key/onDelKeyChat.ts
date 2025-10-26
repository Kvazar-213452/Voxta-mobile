import { Socket } from "socket.io";
import { getMongoClient } from "../../../models/mongoClient";
import { verifyAuth } from "../../../utils/verifyAuth";
import { Db } from "mongodb";

export function onDelKeyChat(socket: Socket): void {
  socket.on("del_key_chat", async (data: { id: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      const client = await getMongoClient();
      const db: Db = client.db("chats");

      const chatId = data.id;

      try {
        const collection = db.collection<{ _id: string; [key: string]: any }>(chatId);
        
        const result = await collection.updateOne(
          { _id: "config" },
          { $unset: { key: "" } }
        );

        if (result.modifiedCount > 0) {
          socket.emit("del_key_chat", { code: 1 });
        } else {
          socket.emit("del_key_chat", { code: 0, error: "config_not_found_or_no_key" });
        }
      } catch (err) {
        console.error(`DB error for chat ${chatId}:`, err);
        socket.emit("del_key_chat", { code: 0, error: "db_error" });
      }
    } catch (err) {
      console.error("Unexpected error in del_key_chat:", err);
      socket.emit("del_key_chat", { code: 0, error: "internal_error" });
    }
  });
}
