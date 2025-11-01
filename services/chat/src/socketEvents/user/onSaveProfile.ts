import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { Db } from "mongodb";
import { verifyAuth } from "../../utils/verifyAuth";
import { uploadAvatar } from "../../utils/uploadData";
import { decryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";

export function onSaveProfile(socket: Socket): void {
  socket.on("save_profile", async (data: { data: any, type: string, key: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      let dataDec: any = await decryptionMsg(data.data);
      dataDec = safeParseJSON(dataDec);

      const client = await getMongoClient();
      const db: Db = client.db("users");
      const collection = db.collection<any>(String(dataDec.id));

      const update: any = {
        name: dataDec.data.name,
        desc: dataDec.data.desc,
      };

      if (dataDec.data.avatar !== null) {
        const avatarUrl = await uploadAvatar(dataDec.data.avatar);
        update.avatar = avatarUrl;
      }

      const result = await collection.updateOne(
        { _id: "config" },
        { $set: update }
      );

      if (result.modifiedCount === 0) {
        socket.emit("save_profile", { code: 0 });
        return;
      }

      socket.emit("save_profile", { code: 1 });
    } catch (error) {
      console.error("Error saving chat settings:", error);
      socket.emit("save_profile", { code: 0 });
    }
  });
}
