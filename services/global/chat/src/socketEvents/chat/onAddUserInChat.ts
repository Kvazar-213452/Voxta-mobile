import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { Db } from "mongodb";
import { verifyAuth } from "../../utils/verifyAuth";
import { getServerIdToChat } from "../../utils/serverChats";
import { getIO } from '../../main';

export function onAddUserInChat(socket: Socket): void {
  socket.on("add_user_in_chat", async (data: { id: string, userId: string, typeChat: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;
      
      if (data.typeChat === 'server') {
        let idServer = getServerIdToChat(data.id);

        getIO().to(String(idServer)).emit("add_user_in_chat", {
          idChat: data.id,
          from: socket.data.userId,
          userId: data.userId
        });
      } else {
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
      }
    } catch (error) {
      console.error("Error adding user to chat:", error);
      socket.emit("add_user_in_chat", { code: 0});
    }
  });
}
