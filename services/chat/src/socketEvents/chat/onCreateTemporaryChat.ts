import { Socket } from "socket.io";
import { Db, Collection } from "mongodb";
import { verifyAuth } from "../../utils/verifyAuth";
import { generateId } from "../../utils/generateId";
import { sendCreateChat } from "../../utils/sendCreateChat";
import { getMongoClient } from "../../models/mongoClient";
import { uploadAvatar } from "../../utils/uploadData";
import { decryptionMsg, encryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";
import { CONFIG } from "../../utils/config/config";
import axios from "axios";

export function onCreateTemporaryChat(socket: Socket): void {
  socket.on("create_temporary_chat", async (data: { data: any, type: string, key: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      let dataDec: any = await decryptionMsg(data.data, data.type);
      dataDec = safeParseJSON(dataDec);

      if (dataDec.chat.avatar) {
        const avatarUrl = await uploadAvatar(dataDec.chat.avatar);
        dataDec.chat.avatar = avatarUrl;
      }

      const client = await getMongoClient();
      const db: Db = client.db("chats");

      let chatId: string = generateId();
      while (await db.listCollections({ name: chatId }).hasNext()) {
        chatId = generateId();
      }

      const chatCollection: Collection = db.collection(chatId);

      const dataConfig = {
        _id: "config" as any,
        type: dataDec.chat.privacy,
        avatar: dataDec.chat.avatar,
        participants: [socket.data.userId],
        name: dataDec.chat.name,
        createdAt: new Date().toISOString(),
        desc: dataDec.chat.desc,
        owner: socket.data.userId,
        expirationHours: dataDec.chat.expirationHours,
        password: dataDec.chat.password
      }

      await chatCollection.insertOne(dataConfig);

      const usersDb: Db = client.db("users");
      const userCollection: Collection = usersDb.collection(socket.data.userId);

      await userCollection.updateOne(
        { _id: "config" as any },
        { $addToSet: { chats: chatId, type: dataDec.chat.privacy } }
      );

      await axios.post(`${CONFIG.MICROSERVICES_SITE}/set_chat`, {
        chat: chatId,
        createdAt: new Date().toISOString(),
        expirationHours: dataDec.chat.expirationHours,
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      });

      sendCreateChat(socket.data.userId, JSON.stringify(await encryptionMsg(data.key, JSON.stringify({ data: dataConfig }), data.type)), chatId);
    } catch (error: unknown) {
      console.log("CONFIG DOC:", error);
      let errorMessage = "Unknown error";
      if (error instanceof Error) {
        errorMessage = error.message;
      }
      socket.emit("chat_created", { code: 0, error: errorMessage });
    }
  });
}