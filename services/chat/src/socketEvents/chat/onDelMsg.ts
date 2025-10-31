import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { Db, ObjectId } from "mongodb";
import { verifyAuth } from "../../utils/verifyAuth";
import { getServerIdToChat } from "../../utils/serverChats";
import { getIO } from '../../utils/config/io';
import { decryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";

export function onDelMsg(socket: Socket): void {
  socket.on("del_msg", async (data: { data: any, type: string, key: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      let dataDec: any = await decryptionMsg(data.data, data.type);
      dataDec = safeParseJSON(dataDec);

      const client = await getMongoClient();

      if (dataDec.typeChat === 'server') {
        let idServer = getServerIdToChat(dataDec.id);

        getIO().to(String(idServer)).emit("del_user_in_chat", {
          idChat: dataDec.id,
          from: socket.data.userId,
          userId: socket.data.userId
        });
      } else {
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
      }

      socket.emit("del_msg", { code: 1 });
    } catch (error) {
      console.error("Error deleting user from chat:", error);
      socket.emit("del_msg", { code: 0 });
    }
  });
}
