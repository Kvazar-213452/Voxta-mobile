import { Socket } from "socket.io";
import jwt from "jsonwebtoken";
import fs from "fs";
import path from "path";
import axios from "axios";
import { getMongoClient } from "../utils/mongoClient";
import { CONFIG } from "../utils/config/config";
import { TransforUser } from "../utils/transform";
import CryptoFunc from "../utils/cryptoFunc";
import { safeParseJSON } from "../utils/utils";
import Helpers from "./helpers";

export default class ServerEvents {
  public static onAuthenticate(socket: Socket): void {
    socket.on("authenticate", async ({ data, type, key }) => {
      try {
        let decrypted = await CryptoFunc.decryptionMsg(data);
        decrypted = safeParseJSON(decrypted);

        if (!decrypted || !decrypted.token) {
          return Helpers.fail(socket, "authenticated", type, { error: "invalid_token" });
        }

        let decoded: { userId: string };
        try {
          decoded = jwt.verify(decrypted.token, CONFIG.SECRET_KEY) as { userId: string };
        } catch {
          return Helpers.fail(socket, "authenticated", type, { error: "jwt_invalid" });
        }

        console.log(`User ${decoded.userId} authenticated.`);

        socket.data.userId = decoded.userId;
        socket.data.token = decrypted.token;
        socket.data.typeUser = "user";

        const client = await getMongoClient();
        const db = client.db("users");
        const collection = db.collection<any>(decoded.userId);

        const userConfig = await collection.findOne({ _id: "config" });
        if (!userConfig) {
          return Helpers.fail(socket, "authenticated", type, { error: "user_not_found" });
        }

        const userKeyDir = path.join("keys", decoded.userId);
        if (!fs.existsSync(userKeyDir)) {
          fs.mkdirSync(userKeyDir, { recursive: true });
        }

        const keyResp = await axios.post(`${CONFIG.MICROSERVICES_CRYPTO}generate`);
        const { publicKey, privateKey } = keyResp.data.result;

        fs.writeFileSync(path.join(userKeyDir, "public.pem"), publicKey);
        fs.writeFileSync(path.join(userKeyDir, "private.pem"), privateKey);

        const responsePayload = {
          code: 1,
          user: TransforUser.transforUser(userConfig)
        };

        const encryptedResponse = await CryptoFunc.encryptionMsg(
          key,
          JSON.stringify(responsePayload)
        );

        socket.emit("authenticated", {
          data: encryptedResponse
        });

        const meta = {
          socketId: socket.id,
          connected: socket.connected,
          namespace: socket.nsp.name,
          rooms: Array.from(socket.rooms),
          transport: socket.conn.transport.name,
          protocol: socket.conn.protocol,
          ip: socket.handshake.address,
          remoteAddress: socket.conn.remoteAddress,
          headers: socket.handshake.headers,
          userAgent: socket.handshake.headers["user-agent"],
          language: socket.handshake.headers["accept-language"],
          handshakeTime: new Date().toISOString(),
        };

        const infoDoc = await collection.findOne({ _id: "info_user" });

        if (!infoDoc) {
          await collection.insertOne({
            _id: "info_user",
            info: [meta]
          });
        } else {
          await collection.updateOne(
            { _id: "info_user" },
            { $push: { info: { $each: [meta], $position: 0 } } as any }
          );
        }

      } catch (error) {
        console.error("AUTH ERROR:", error);
        Helpers.fail(socket, "authenticated", "auth", { error: "server_error" });
        socket.disconnect();
      }
    });
  }

  public static onDisconnect(socket: Socket): void {
    socket.on("disconnect", () => {
      console.log("client disconnect", socket.id);
    });
  }

  public static onError(socket: Socket): void {
    socket.on("error", (error) => {
      console.error("error:", error);
    });
  }
}
