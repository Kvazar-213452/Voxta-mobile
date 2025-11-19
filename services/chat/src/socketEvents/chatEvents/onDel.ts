import { Socket } from "socket.io";
import { getMongoClient } from "../../utils/mongoClient";
import { Db, ObjectId } from "mongodb";
import CryptoFunc from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";
import Helpers from "../helpers";

export default class delEvents {
  public static onDelChat(socket: Socket): void {
    socket.on("del_chat", async (data: { chatId: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "del_chat_return", "unauthorized");

      try {
        const client = await getMongoClient();
        const chatDb: Db = client.db("chats");
        const chatCol = chatDb.collection<{ _id: string; [key: string]: any }>(data.chatId);
        const chatConfig: any = await chatCol.findOne({ _id: "config" });

        const dbUsers: Db = client.db("users");
        for (const userId of chatConfig.participants) {
          const userCollection = dbUsers.collection(userId);
          const userdata = await userCollection.findOne({ _id: "config" as any });

          if (userdata && Array.isArray(userdata.chats)) {
            const updatedChats = userdata.chats.filter((id: string) => id !== data.chatId);
            await userCollection.updateOne(
              { _id: "config" as any },
              { $set: { chats: updatedChats } }
            );
          }
        }

        await chatCol.drop();
        socket.emit("del_chat_return", { code: 1 });

      } catch (error) {
        Helpers.fail(socket, "del_chat_return", "server_error");
      }
    });
  }

  public static onDelMemberInChat(socket: Socket): void {
    socket.on("del_user_in_chat", async (data: { id: string, userId: string, typeChat: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "del_user_in_chat", "unauthorized");

      try {
        const db: Db = (await getMongoClient()).db("chats");
        const collection = db.collection<any>(data.id);

        const result = await collection.updateOne(
          { _id: "config" },
          { $pull: { participants: String(data.userId) as any } }
        );

        if (result.modifiedCount === 0)
          return Helpers.fail(socket, "del_user_in_chat", "not_modified");

        socket.emit("del_user_in_chat", { code: 1 });

      } catch (error) {
        Helpers.fail(socket, "del_user_in_chat", "server_error");
      }
    });
  }

  public static onDelMsg(socket: Socket): void {
    socket.on("del_msg", async (data: { data: any, type: string, key: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "del_msg", "unauthorized");

      try {
        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
        dataDec = safeParseJSON(dataDec);

        const db: Db = (await getMongoClient()).db("chats");
        const collection = db.collection<any>(String(dataDec.idChat));

        await collection.deleteOne({
          _id: ObjectId.isValid(dataDec.idMsg) ? new ObjectId(dataDec.idMsg) : dataDec.idMsg
        });

        socket.emit("del_msg", { code: 1 });

      } catch (error) {
        Helpers.fail(socket, "del_msg", "server_error");
      }
    });
  }

  public static onDelSelfInChat(socket: Socket): void {
    socket.on("del_user_in_chat_self", async (data: { data: any, type: string, key: string }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return Helpers.fail(socket, "del_user_in_chat_self", "unauthorized");

      try {
        let dataDec: any = await CryptoFunc.decryptionMsg(data.data);
        dataDec = safeParseJSON(dataDec);

        const client = await getMongoClient();

        const chatsDb: Db = client.db("chats");
        const chatCol = chatsDb.collection<any>(String(dataDec.id));

        await chatCol.updateOne(
          { _id: "config" },
          { $pull: { participants: String(socket.data.userId) as any } }
        );

        const usersDb: Db = client.db("users");
        const userCol = usersDb.collection<any>(String(socket.data.userId));

        await userCol.updateOne(
          { _id: "config" },
          { $pull: { chats: String(dataDec.id) as any } }
        );

        socket.emit("del_user_in_chat_self", { code: 1 });

      } catch (error) {
        Helpers.fail(socket, "del_user_in_chat_self", "server_error");
      }
    });
  }
}
