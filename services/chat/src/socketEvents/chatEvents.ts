import { Socket } from "socket.io";
import { getMongoClient } from "../utils/mongoClient";
import { verifyAuth } from "../utils/verifyAuth";
import { Db, Collection, ObjectId } from "mongodb";
import { generateId } from "../utils/generateId";
import { sendCreateChat } from "../utils/sendCreateChat";
import { uploadAvatar } from "../utils/uploadData";
import CryptoFunc from "../utils/cryptoFunc";
import { safeParseJSON } from "../utils/utils";
import { onSendMessage as onSendMessage1 } from "../utils/sendCreateChat";
import { uploadFile } from "../utils/uploadData";
import { CONFIG } from "../utils/config/config";
import axios from "axios";

import Helpers from "./helpers";

export class chatEvents {
  public static onAddUserInChat(socket: Socket): void {
    socket.on("add_user_in_chat", async (data: { id: string, userId: string, typeChat: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;

        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<any>(data.id);

        const result = await collection.updateOne(
          { _id: "config" },
          { $addToSet: { participants: String(data.userId) } }
        );

        if (result.matchedCount === 0) {
          socket.emit("add_user_in_chat", { code: 0 });
          return;
        }

        socket.emit("add_user_in_chat", { code: 1 });

      } catch (error) {
        console.error("Error adding user to chat:", error);
        socket.emit("add_user_in_chat", { code: 0 });
      }
    });
  }

  public static onCreateChat(socket: Socket): void {
    socket.on("create_chat", async (data: { data: any, type: string, key: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;

        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
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
        console.log("CONFIG DOC:", error);
        let errorMessage = "Unknown error";
        if (error instanceof Error) {
          errorMessage = error.message;
        }
        socket.emit("chat_created", { code: 0, error: errorMessage });
      }
    });
  }


  public static onCreateTemporaryChat(socket: Socket): void {
    socket.on("create_temporary_chat", async (data: { data: any, type: string, key: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;

        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
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
        console.log(dataDec.chat)
        await axios.post(`${CONFIG.MICROSERVICES_SITE}set_chat`, {
          chat: chatId,
          createdAt: new Date().toISOString(),
          expirationHours: dataDec.chat.expirationHours,
          pasw: dataDec.chat.password
        }, {
          headers: {
            'Content-Type': 'application/json'
          }
        });

        sendCreateChat(socket.data.userId, JSON.stringify(await CryptoFunc.encryptionMsg(data.key, JSON.stringify({ data: dataConfig }))), chatId);
      } catch (error: unknown) {
        console.log("CONFIG DOC:");
        let errorMessage = "Unknown error";
        if (error instanceof Error) {
          errorMessage = error.message;
        }
        socket.emit("chat_created", { code: 0, error: errorMessage });
      }
    });
  }

  public static onDelChat(socket: Socket): void {
    socket.on("del_chat", async (data: { chatId: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;
  
        const client = await getMongoClient();
        const chatDb: Db = client.db("chats");
  
        const chatId = data.chatId;
  
        const chatCol = chatDb.collection<{ _id: string;[key: string]: any }>(chatId);
        const chatConfig: any = await chatCol.findOne({ _id: "config" });
  
        const dbUsers: Db = client.db("users");
        for (const userId of chatConfig.participants) {
          const userCollection = dbUsers.collection(userId);
          const userdata = await userCollection.findOne({ _id: "config" as any });
  
          if (userdata && Array.isArray(userdata.chats)) {
            const updatedChats = userdata.chats.filter((id: string) => id !== chatId);
            await userCollection.updateOne(
              { _id: "config" as any },
              { $set: { chats: updatedChats } }
            );
          }
        }
  
        await chatCol.drop();
  
        socket.emit("del_chat_return", { code: 1 });
  
      } catch (error) {
        socket.emit("del_chat_return", { code: 0, error: "server_error" });
      }
    });
  }

  public static onDelMemberInChat(socket: Socket): void {
    socket.on("del_user_in_chat", async (data: { id: string, userId: string, typeChat: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;
  
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<any>(data.id);
  
        const result = await collection.updateOne(
          { _id: "config" },
          { $pull: { participants: String(data.userId) as any } }
        );
  
        if (result.modifiedCount === 0) {
          socket.emit("del_user_in_chat", { code: 0 });
          return;
        }
  
        socket.emit("del_user_in_chat", { code: 1 });
  
      } catch (error) {
        console.error("Error deleting user from chat:", error);
        socket.emit("del_user_in_chat", { code: 0 });
      }
    });
  }
  
  public static onDelMsg(socket: Socket): void {
    socket.on("del_msg", async (data: { data: any, type: string, key: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;
  
        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
        dataDec = safeParseJSON(dataDec);
  
        const client = await getMongoClient();
  
        const db: Db = client.db("chats");
        const collection = db.collection<any>(String(dataDec.idChat));
  
        const result = await collection.deleteOne({
          _id: ObjectId.isValid(dataDec.idMsg) ? new ObjectId(dataDec.idMsg) : dataDec.idMsg
        });
  
        if (result.deletedCount > 0) {
          console.log(`Документ з _id=${dataDec.idMsg} видалено`);
        } else {
          console.log(`Документ з _id=${dataDec.idMsg} не знайдено`);
        }
  
        socket.emit("del_msg", { code: 1 });
      } catch (error) {
        console.error("Error deleting user from chat:", error);
        socket.emit("del_msg", { code: 0 });
      }
    });
  }
  
  public static onDelSelfInChat(socket: Socket): void {
    socket.on("del_user_in_chat_self", async (data: { data: any, type: string, key: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;
  
        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
        dataDec = safeParseJSON(dataDec);
  
        const client = await getMongoClient();
  
        const db: Db = client.db("chats");
        const collection = db.collection<any>(String(dataDec.id));
  
        await collection.updateOne(
          { _id: "config" },
          { $pull: { participants: String(socket.data.userId) as any } }
        );
  
        const usersDb: Db = client.db("users");
        const usersCollection = usersDb.collection<any>(String(socket.data.userId));
  
        await usersCollection.updateOne(
          { _id: "config" },
          { $pull: { chats: String(dataDec.id) as any } }
        );
  
        socket.emit("del_user_in_chat_self", { code: 1 });
      } catch (error) {
        console.error("Error deleting user from chat:", error);
        socket.emit("del_user_in_chat_self", { code: 0 });
      }
    });
  }

  public static onGetInfoChat(socket: Socket): void {
    socket.on("get_info_chat", async (data: { chatId: string, type: string, typeChat: string }) => {
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
            socket.emit("chat_info", { code: 1, chat: chatWithoutId, type: data.type });
          } else {
            socket.emit("chat_info", { code: 0, error: "config_not_found", type: data.type });
          }
        } catch (err) {
          console.error(`DB error for chat ${chatId}:`, err);
          socket.emit("chat_info", { code: 0, error: "db_error", type: data.type });
        }
  
      } catch (error) {
        socket.emit("chat_info", { code: 0, error: "server_error", type: data.type });
      }
    });
  }
  
 public static onGetInfoChatFix(socket: Socket): void {
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

  public static onGetInfoChats(socket: Socket): void {
    socket.on("getInfoChats", async (data: { data: any, type: string, key: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;
  
        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
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
  
        socket.emit("chats_info", { data: await CryptoFunc.encryptionMsg(data.key, JSON.stringify({code: 1, chats: result})) });
  
      } catch (error) {
        console.error("getInfoChats error:", error);
        socket.emit("chats_info", { code: 0, error: "server_error" });
      }
    });
  }
  
  public static async onLoadChatContent(socket: Socket): Promise<void> {
    socket.on("load_chat_content", async (data: { data: any, type: string, key: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;
  
        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
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
            data: await CryptoFunc.encryptionMsg(data.key, JSON.stringify(messageToInsert))
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
            data: await CryptoFunc.encryptionMsg(data.key, JSON.stringify(messageToInsert))
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
        console.log("CONFIG DOC:", error);
        let errorMessage = "Unknown error";
        if (error instanceof Error) {
          errorMessage = error.message;
        }
        socket.emit("send_new_chat_server", { code: 0, error: errorMessage });
      }
    });
  }
  
  public static onSaveSettingsChat(socket: Socket): void {
    socket.on("save_settings_chat", async (data: { id: string, dataChat: any, typeChat: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;
  
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<any>(data.id);
  
        const update: any = {
          name: data.dataChat.name,
          desc: data.dataChat.desc,
        };
  
        if (data.dataChat.avatar !== null) {
          const avatarUrl = await uploadAvatar(data.dataChat.avatar);
          update.avatar = avatarUrl;
        }
  
        const result = await collection.updateOne(
          { _id: "config" },
          { $set: update }
        );
  
        if (result.modifiedCount === 0) {
          socket.emit("save_settings_chat", { code: 0 });
          return;
        }
  
        socket.emit("save_settings_chat", { code: 1 });
  
      } catch (error) {
        console.error("Error saving chat settings:", error);
        socket.emit("save_settings_chat", { code: 0 });
      }
    });
  }
  
  public static onSendMessage(socket: Socket): void {
    socket.on("send_message", async (data: { data: any, type: string, key: string }) => {
      try {
        const auth = verifyAuth(socket);
        if (!auth) return;
  
        let dataDec: any = await CryptoFunc.decryptionMsgServer(data.data, auth.userId);
        dataDec = safeParseJSON(dataDec);
  
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        let messageToInsert = {};
        const collection = db.collection<any>(dataDec.chatId);
  
        if (dataDec.message.type == "file") {
          let url = await uploadFile(dataDec.message.content["base64Data"], dataDec.message.content["fileName"]);
  
          messageToInsert = {
            _id: generateId(12),
            sender: dataDec.message.sender,
            content: {
              name: dataDec.message.content["fileName"],
              size: dataDec.message.content["fileSize"],
              url: url
            },
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
  
      } catch (error) {
        console.error("send_message error:", error);
        socket.emit("send_message_return", { code: 0, error: "server_error" });
      }
    });
  }
}