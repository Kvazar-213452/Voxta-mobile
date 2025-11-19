import { Socket } from "socket.io";
import { getMongoClient } from "../../utils/mongoClient";
import { Db, Collection } from "mongodb";
import { generateId } from "../../utils/generateId";
import { sendCreateChat } from "../../utils/sendCreateChat";
import { uploadAvatar } from "../../utils/uploadData";
import CryptoFunc from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";
import { onSendMessage as onSendMessage1 } from "../../utils/sendCreateChat";
import { uploadFile } from "../../utils/uploadData";
import { CONFIG } from "../../utils/config/config";
import axios from "axios";
import Helpers from "../helpers";

export default class Create {
  public static onAddUserInChat(socket: Socket): void {
    socket.on("add_user_in_chat", async (data: { id: string, userId: string, typeChat: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "add_user_in_chat", "unauthorized");

      try {
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<any>(data.id);

        const result = await collection.updateOne(
          { _id: "config" },
          { $addToSet: { participants: String(data.userId) } }
        );

        if (result.matchedCount === 0) return Helpers.fail(socket, "add_user_in_chat", "not_found");

        socket.emit("add_user_in_chat", { code: 1 });

      } catch {
        Helpers.fail(socket, "add_user_in_chat", "server_error");
      }
    });
  }

  public static onCreateChat(socket: Socket): void {
    socket.on("create_chat", async (data: { data: any, type: string, key: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "chat_created", "unauthorized");

      try {
        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
        dataDec = safeParseJSON(dataDec);

        if (dataDec.chat.avatar) dataDec.chat.avatar = await uploadAvatar(dataDec.chat.avatar);

        const client = await getMongoClient();
        const db: Db = client.db("chats");

        let chatId: string = generateId();
        while (await db.listCollections({ name: chatId }).hasNext()) chatId = generateId();

        const chatCollection: Collection = db.collection(chatId);

        const dataConfig = {
          _id: "config" as any,
          type: dataDec.chat.privacy,
          avatar: dataDec.chat.avatar,
          participants: [socket.data.userId],
          name: dataDec.chat.name,
          createdAt: new Date().toISOString(),
          desc: dataDec.chat.description,
          owner: socket.data.userId
        }

        await chatCollection.insertOne(dataConfig);

        const usersDb: Db = client.db("users");
        const userCollection: Collection = usersDb.collection(socket.data.userId);

        await userCollection.updateOne(
          { _id: "config" as any },
          { $addToSet: { chats: chatId, type: dataDec.chat.privacy } }
        );

        sendCreateChat(socket.data.userId, JSON.stringify(await CryptoFunc.encryptionMsg(data.key, JSON.stringify({ data: dataConfig }))), chatId);

      } catch (error: unknown) {
        let errorMessage = "Unknown error";
        if (error instanceof Error) errorMessage = error.message;
        socket.emit("chat_created", { code: 0, error: errorMessage });
      }
    });
  }

  public static onCreateTemporaryChat(socket: Socket): void {
    socket.on("create_temporary_chat", async (data: { data: any, type: string, key: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "chat_created", "unauthorized");

      try {
        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
        dataDec = safeParseJSON(dataDec);

        if (dataDec.chat.avatar) dataDec.chat.avatar = await uploadAvatar(dataDec.chat.avatar);

        const client = await getMongoClient();
        const db: Db = client.db("chats");

        let chatId: string = generateId();
        while (await db.listCollections({ name: chatId }).hasNext()) chatId = generateId();

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

        await axios.post(`${CONFIG.MICROSERVICES_SITE}set_chat`, {
          chat: chatId,
          createdAt: new Date().toISOString(),
          expirationHours: dataDec.chat.expirationHours,
          pasw: dataDec.chat.password
        }, { headers: { 'Content-Type': 'application/json' } });

        sendCreateChat(socket.data.userId, JSON.stringify(await CryptoFunc.encryptionMsg(data.key, JSON.stringify({ data: dataConfig }))), chatId);

      } catch (error: unknown) {
        let errorMessage = "Unknown error";
        if (error instanceof Error) errorMessage = error.message;
        socket.emit("chat_created", { code: 0, error: errorMessage });
      }
    });
  }

  public static onNewChatCreateServer(socket: Socket): void {
    socket.on("send_new_chat_server", async (data: { chat: any }) => {
      try {
        sendCreateChat(data.chat.owner, JSON.stringify(data.chat), data.chat.id);

        const client = await getMongoClient();
        const usersDb: Db = client.db("users");
        const userCollection: Collection = usersDb.collection(String(data.chat.owner));

        await userCollection.updateOne(
          { _id: "config" as any },
          { $addToSet: { chats: data.chat.id } }
        );

        socket.emit("send_new_chat_server", { code: 1 });

      } catch (error: unknown) {
        let errorMessage = "Unknown error";
        if (error instanceof Error) errorMessage = error.message;
        socket.emit("send_new_chat_server", { code: 0, error: errorMessage });
      }
    });
  }

  public static onSaveSettingsChat(socket: Socket): void {
    socket.on("save_settings_chat", async (data: { id: string, dataChat: any, typeChat: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "save_settings_chat", "unauthorized");

      try {
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<any>(data.id);

        const update: any = {
          name: data.dataChat.name,
          desc: data.dataChat.desc,
        };

        if (data.dataChat.avatar !== null) update.avatar = await uploadAvatar(data.dataChat.avatar);

        const result = await collection.updateOne(
          { _id: "config" },
          { $set: update }
        );

        if (result.modifiedCount === 0) return Helpers.fail(socket, "save_settings_chat", "not_modified");

        socket.emit("save_settings_chat", { code: 1 });

      } catch {
        Helpers.fail(socket, "save_settings_chat", "server_error");
      }
    });
  }

  public static onSendMessage(socket: Socket): void {
    socket.on("send_message", async (data: { data: any, type: string, key: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "send_message_return", "unauthorized");

      try {
        let dataDec: any = await CryptoFunc.decryptionMsgServer(data.data, auth.userId);
        dataDec = safeParseJSON(dataDec);

        const client = await getMongoClient();
        const db: Db = client.db("chats");
        let messageToInsert = {};
        const collection = db.collection<any>(dataDec.chatId);

        if (dataDec.message.type == "file") {
          const url = await uploadFile(dataDec.message.content["base64Data"], dataDec.message.content["fileName"]);
          messageToInsert = {
            _id: generateId(12),
            sender: dataDec.message.sender,
            content: { name: dataDec.message.content["fileName"], size: dataDec.message.content["fileSize"], url },
            time: dataDec.message.time,
            type: dataDec.message.type
          };
        } else {
          messageToInsert = {
            _id: generateId(12),
            sender: dataDec.message.sender,
            content: dataDec.message.content,
            time: dataDec.message.time,
            type: dataDec.message.type
          };
        }

        await collection.insertOne(messageToInsert);

        onSendMessage1(await CryptoFunc.encryptionMsg(data.key, JSON.stringify(messageToInsert)));

      } catch {
        Helpers.fail(socket, "send_message_return", "server_error");
      }
    });
  }
}
