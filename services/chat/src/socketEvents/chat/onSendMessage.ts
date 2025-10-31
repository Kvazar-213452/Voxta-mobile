import { Socket } from "socket.io";
import { Db } from "mongodb";
import { getMongoClient } from "../../models/mongoClient";
import { verifyAuth } from "../../utils/verifyAuth";
import { generateId } from "../../utils/generateId";
import { decryptionMsg, encryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";
import { getIO } from "../../utils/config/io";
import { onSendMessage as onSendMessage1 } from "../../utils/sendCreateChat";
import axios from "axios";
import { CONFIG } from "../../utils/config/config";

export function onSendMessage(socket: Socket): void {
  socket.on("send_message", async (data: { data: any, type: string, key: string }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      let dataDec: any = await decryptionMsg(data.data, data.type);
      dataDec = safeParseJSON(dataDec);

      const client = await getMongoClient();
      const db: Db = client.db("chats");
      let messageToInsert = {};
      const collection = db.collection<any>(dataDec.chatId);

      if (dataDec.message.type == "file") {
        let url = await uploadfile(dataDec.message.content["base64Data"], dataDec.message.content["fileName"]);

        messageToInsert = {
          _id: generateId(12),
          sender: dataDec.message.sender,
          content: {
            name: dataDec.message.content["fileName"],
            size: dataDec.message.content["fileSize"],
            url: url
          },
          time: dataDec.message.time,
          type: dataDec.message.type
        };
      } else {
        messageToInsert = {
          _id: generateId(12),
          sender: dataDec.message.sender,
          content: dataDec.message.content,
          time: dataDec.message.time,
          type: dataDec.message.type
        };
      }

      await collection.insertOne(messageToInsert);

      onSendMessage1(await encryptionMsg(data.key, JSON.stringify(messageToInsert), data.type));

    } catch (error) {
      console.error("send_message error:", error);
      socket.emit("send_message_return", { code: 0, error: "server_error" });
    }
  });
}

async function uploadfile(base64String: string, name: string): Promise<string> {
  const matches = base64String.match(/^data:(.+);base64,(.+)$/);
  if (!matches) throw new Error("Invalid base64 string");

  try {
    const response = await axios.post(`${CONFIG.MICROSERVICES_DATA}upload_file_base64`, {
      file: base64String,
      name: name
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    return response.data.url;
  } catch (error) {
    console.error('Error uploading avatar:', error);
    return "";
  }
}
