import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { verifyAuth } from "../../utils/verifyAuth";
import { Db } from "mongodb";
import { decryptionMsg, encryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";

export async function onLoadChatContent(socket: Socket): Promise<void> {
  socket.on("load_chat_content", async (data: { data: any, type: string, key: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      let dataDec: any = await decryptionMsg(data.data);
      dataDec = safeParseJSON(dataDec);

      const client = await getMongoClient();
      const db: Db = client.db("chats");

      const collection = db.collection<any>(dataDec.chatId);

      const config = await collection.findOne({ _id: "config" });
      if (!config) {
        throw new Error("Config not found");
      }

      const participants: string[] = config.participants || [];
      const participantsData: Record<string, { avatar: string; name: string }> = {};
      const usersDb: Db = client.db("users");

      for (const participantId of participants) {
        const userCollection = usersDb.collection<any>(participantId);
        const userConfig = await userCollection.findOne({ _id: "config" });

        participantsData[participantId] = {
          avatar: userConfig?.avatar || "",
          name: userConfig?.name || ""
        };
      }

      if (dataDec.type === "online") {
        let messages = await collection
          .find({ _id: { $ne: "config" } })
          .sort({ _id: -1 })
          .limit(100)
          .toArray();

        const messageToInsert = {
          code: 1,
          chatId: dataDec.chatId,
          messages: messages.reverse(),
          participants: participantsData,
          type: data.type
        };

        socket.emit("load_chat_content_return", {
          code: 1,
          data: await encryptionMsg(data.key, JSON.stringify(messageToInsert))
        });
      } else {
        const messageToInsert = {
          code: 1,
          chatId: dataDec.chatId,
          participants: participantsData,
          type: data.type
        };

        socket.emit("load_chat_content_return", {
          code: 1,
          data: await encryptionMsg(data.key, JSON.stringify(messageToInsert))
        });
      }

    } catch (err) {
      console.log(`Error loading chat content:`, err);
      socket.emit("load_chat_content_return", {
        code: 0,
        error: "server_error"
      });
    }
  });
}
