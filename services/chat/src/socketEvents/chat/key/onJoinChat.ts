import { Socket } from "socket.io";
import { getMongoClient } from "../../../models/mongoClient";
import { verifyAuth } from "../../../utils/verifyAuth";
import { Db } from "mongodb";

export function onJoinChat(socket: Socket): void {
  socket.on("join_chat", async (data: { key: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

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
        socket.emit("join_chat", { code: 0, error: "no_matches" });
      }

    } catch (err) {
      console.error("Unexpected error in join_chat:", err);
      socket.emit("join_chat", { code: 0, error: "internal_error" });
    }
  });
}
