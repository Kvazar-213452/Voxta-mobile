import { Socket } from "socket.io";
import { getMongoClient } from "../../models/mongoClient";
import { Db } from "mongodb";
import { verifyAuth } from "../../utils/verifyAuth";
import { uploadAvatar } from "../../utils/uploadData";
import { getServerIdToChat } from "../../utils/serverChats";
import { getIO } from '../../main';

export function onSaveSettingsChat(socket: Socket): void {
  socket.on("save_settings_chat", async (data: { id: string, dataChat: any, typeChat: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      if (data.typeChat === 'server') {
        let idServer = getServerIdToChat(data.id);

        getIO().to(String(idServer)).emit("save_settings_chat", {
          idChat: data.id,
          from: socket.data.userId,
          dataChat: data.dataChat
        });
      } else {
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<any>(data.id);

        const update: any = {
          name: data.dataChat.name,
          desc: data.dataChat.desc,
        };

        if (data.dataChat.avatar !== null) {
          const avatarUrl = await uploadAvatar(data.dataChat.avatar);
          update.avatar = avatarUrl;
        }

        const result = await collection.updateOne(
          { _id: "config" },
          { $set: update }
        );

        if (result.modifiedCount === 0) {
          socket.emit("save_settings_chat", { code: 0 });
          return;
        }

        socket.emit("save_settings_chat", { code: 1 });
      }
    } catch (error) {
      console.error("Error saving chat settings:", error);
      socket.emit("save_settings_chat", { code: 0 });
    }
  });
}
