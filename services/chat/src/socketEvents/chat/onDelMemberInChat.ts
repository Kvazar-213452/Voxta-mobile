import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { Db } from "mongodb";
import { verifyAuth } from "../../utils/verifyAuth";

export function onDelMemberInChat(socket: Socket): void {
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
