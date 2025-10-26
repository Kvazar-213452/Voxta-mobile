import { Socket } from "socket.io";
import { sendCreateChat } from "../../utils/sendCreateChat";
import { Db, Collection } from "mongodb";
import { getMongoClient } from "../../models/mongoClient";

export function onNewChatCreateServer(socket: Socket): void {
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
