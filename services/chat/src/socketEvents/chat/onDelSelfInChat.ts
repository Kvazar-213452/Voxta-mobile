import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { Db } from "mongodb";
import { verifyAuth } from "../../utils/verifyAuth";
import { decryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";

export function onDelSelfInChat(socket: Socket): void {
  socket.on("del_user_in_chat_self", async (data: { data: any, type: string, key: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      let dataDec: any = await decryptionMsg(data.data, data.type);
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