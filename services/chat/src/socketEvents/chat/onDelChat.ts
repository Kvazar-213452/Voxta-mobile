import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { Db } from "mongodb";
import { verifyAuth } from "../../utils/verifyAuth";

export function onDelChat(socket: Socket): void {
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