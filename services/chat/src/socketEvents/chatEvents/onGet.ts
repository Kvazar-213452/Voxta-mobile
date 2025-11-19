import { Socket } from "socket.io";
import { getMongoClient } from "../../utils/mongoClient";
import CryptoFunc from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";

import Helpers from "../helpers";

export default class chatEvents {
  public static onGetInfoChat(socket: Socket): void {
    socket.on("get_info_chat", async (data: { chatId: string, type: string, typeChat: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "chat_info", "unauthorized");

      try {
        const db = (await getMongoClient()).db("chats");
        const chat: any = await db.collection(data.chatId).findOne({ _id: "config" as any });

        if (!chat)
          return Helpers.fail(socket, "chat_info", "config_not_found");

        delete chat._id;

        socket.emit("chat_info", { code: 1, chat, type: data.type });

      } catch (err) {
        console.error("chat_info error:", err);
        Helpers.fail(socket, "chat_info", "server_error");
      }
    });
  }

  public static onGetInfoChatFix(socket: Socket): void {
    socket.on("get_info_chat_fix", async (data: { chatId: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "get_info_chat_fix_return", "unauthorized");

      try {
        const db = (await getMongoClient()).db("chats");
        const chat: any = await db.collection(data.chatId).findOne({ _id: "config" as any });

        if (!chat)
          return Helpers.fail(socket, "get_info_chat_fix_return", "config_not_found");

        delete chat._id;

        socket.emit("get_info_chat_fix_return", { code: 1, chat });

      } catch (err) {
        console.error("get_info_chat_fix error:", err);
        Helpers.fail(socket, "get_info_chat_fix_return", "server_error");
      }
    });
  }

  public static onGetInfoChats(socket: Socket): void {
    socket.on("getInfoChats", async (data: { data: any, type: string, key: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "chats_info", "unauthorized");

      try {
        let decrypted = safeParseJSON(await CryptoFunc.decryptionMsg(data.data));

        const db = (await getMongoClient()).db("chats");
        const result: Record<string, any> = {};

        for (const chatId of decrypted.chats) {
          try {
            const chat = await db.collection(chatId).findOne({ _id: "config" as any });
            if (chat) result[chatId] = chat;
          } catch (err) {
            console.error(`Chat DB read error for ${chatId}:`, err);
          }
        }

        const encrypted = await CryptoFunc.encryptionMsg(
          data.key,
          JSON.stringify({ code: 1, chats: result })
        );

        socket.emit("chats_info", { data: encrypted });

      } catch (err) {
        console.error("getInfoChats critical:", err);
        Helpers.fail(socket, "chats_info", "server_error");
      }
    });
  }

  public static async onLoadChatContent(socket: Socket): Promise<void> {
    socket.on("load_chat_content", async (data: { data: any, type: string, key: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "load_chat_content_return", "unauthorized");

      try {
        let decrypted = safeParseJSON(await CryptoFunc.decryptionMsg(data.data));

        const client = await getMongoClient();
        const chatsDb = client.db("chats");
        const usersDb = client.db("users");

        const collection = chatsDb.collection(decrypted.chatId);

        const config = await collection.findOne({ _id: "config" as any });
        if (!config) return Helpers.fail(socket, "load_chat_content_return", "config_not_found");

        const participantsData = {};
        for (const userId of config.participants || []) {
          const userCfg = await usersDb.collection(userId).findOne({ _id: "config" as any });
          participantsData[userId] = {
            avatar: userCfg?.avatar || "",
            name: userCfg?.name || ""
          };
        }

        let messages: any = [];
        if (decrypted.type === "online") {
          messages = await collection
            .find({ _id: { $ne: "config" as any } })
            .sort({ _id: -1 })
            .limit(100)
            .toArray();
          messages.reverse();
        }

        const response = {
          code: 1,
          chatId: decrypted.chatId,
          participants: participantsData,
          messages,
          type: data.type
        };

        const encrypted = await CryptoFunc.encryptionMsg(data.key, JSON.stringify(response));

        socket.emit("load_chat_content_return", { code: 1, data: encrypted });

      } catch (err) {
        console.error("load_chat_content error:", err);
        Helpers.fail(socket, "load_chat_content_return", "server_error");
      }
    });
  }
}
