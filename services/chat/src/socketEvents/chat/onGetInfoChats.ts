import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { verifyAuth } from "../../utils/verifyAuth";
import { Db } from "mongodb";
import { decryptionMsg, encryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";

export function onGetInfoChats(socket: Socket): void {
  socket.on("getInfoChats", async (data: { data: any, type: string, key: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      let dataDec: any = await decryptionMsg(data.data);
      dataDec = safeParseJSON(dataDec);

      const client = await getMongoClient();
      const db: Db = client.db("chats");

      const result: Record<string, any> = {};

      const remainingChats = dataDec.chats.filter(chatId => !result.hasOwnProperty(chatId));
      
      for (const chatId of remainingChats) {
        try {
          const collection = db.collection<{ _id: string; [key: string]: any }>(chatId);
          const chatConfig = await collection.findOne({ _id: "config" });

          if (chatConfig) {
            result[chatId] = chatConfig;
          }
        } catch (err) {
          console.error(`DB chat error ${chatId}:`, err);
        }
      }

      socket.emit("chats_info", { data: await encryptionMsg(data.key, JSON.stringify({code: 1, chats: result})) });

    } catch (error) {
      console.error("getInfoChats error:", error);
      socket.emit("chats_info", { code: 0, error: "server_error" });
    }
  });
}
