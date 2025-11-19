import { Socket } from "socket.io";
import { getMongoClient } from "../../utils/mongoClient";
import { Db } from "mongodb";
import { generateId } from "../../utils/generateId";
import Helpers from "../helpers";

export default class keyChat {
  public static onDelKeyChat(socket: Socket): void {
    socket.on("del_key_chat", async (data: { id: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "del_key_chat", "unauthorized");

      try {
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<{ _id: string; [key: string]: any }>(data.id);

        const result = await collection.updateOne(
          { _id: "config" },
          { $unset: { key: "" } }
        );

        if (result.modifiedCount > 0) {
          socket.emit("del_key_chat", { code: 1 });
        } else {
          Helpers.fail(socket, "del_key_chat", "config_not_found_or_no_key");
        }
      } catch {
        Helpers.fail(socket, "del_key_chat", "db_error");
      }
    });
  }

  public static onGenerateKeyChat(socket: Socket): void {
    socket.on("generate_key_chat", async (data: { id: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "generate_key_chat", "unauthorized");

      try {
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<{ _id: string; [key: string]: any }>(data.id);

        const newKey = generateId(9);
        const result = await collection.updateOne(
          { _id: "config" },
          { $set: { key: newKey } }
        );

        if (result.matchedCount > 0) {
          socket.emit("generate_key_chat", { code: 1, key: newKey });
        } else {
          Helpers.fail(socket, "generate_key_chat", "config_not_found");
        }
      } catch {
        Helpers.fail(socket, "generate_key_chat", "db_error");
      }
    });
  }

  public static onGetKeyChat(socket: Socket): void {
    socket.on("get_key_chat", async (data: { id: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "get_key_chat", "unauthorized");

      try {
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<{ _id: string; [key: string]: any }>(data.id);
        const chatConfig = await collection.findOne({ _id: "config" });

        if (chatConfig) {
          const { _id, ...chatWithoutId } = chatConfig;
          socket.emit("get_key_chat", { code: 1, key: chatWithoutId["key"] });
        } else {
          Helpers.fail(socket, "get_key_chat", "config_not_found");
        }
      } catch {
        Helpers.fail(socket, "get_key_chat", "db_error");
      }
    });
  }

  public static onJoinChat(socket: Socket): void {
    socket.on("join_chat", async (data: { key: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "join_chat", "unauthorized");

      try {
        const client = await getMongoClient();
        const chatsDb: Db = client.db("chats");
        const collections = await chatsDb.listCollections().toArray();
        let matchedChatName: string | null = null;

        for (const collInfo of collections) {
          const collection = chatsDb.collection<{ _id: string; key?: string; participants?: string[] }>(collInfo.name);
          const chatConfig = await collection.findOne({ _id: "config" });

          if (chatConfig && chatConfig.key === data.key) {
            await collection.updateOne(
              { _id: "config" },
              { $addToSet: { participants: String(socket.data.userId) } }
            );
            matchedChatName = collInfo.name;
            break;
          }
        }

        if (matchedChatName) {
          const usersDb: Db = client.db("users");
          const usersCollection = usersDb.collection<{ _id: string; chats?: string[] }>(String(socket.data.userId));
          await usersCollection.updateOne(
            { _id: "config" },
            { $addToSet: { chats: matchedChatName } }
          );

          socket.emit("join_chat", { code: 1, matchedChats: [matchedChatName] });
        } else {
          Helpers.fail(socket, "join_chat", "no_matches");
        }
      } catch {
        Helpers.fail(socket, "join_chat", "internal_error");
      }
    });
  }
}
