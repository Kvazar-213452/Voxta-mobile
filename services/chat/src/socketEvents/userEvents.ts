import { Socket } from "socket.io";
import { Db } from "mongodb";
import fs from "fs";
import { getMongoClient } from "../utils/mongoClient";
import Helpers from "./helpers";
import { TransforUser } from "../utils/transform";
import { safeParseJSON } from "../utils/utils";
import { uploadAvatar } from "../utils/uploadData";
import CryptoFunc from "../utils/cryptoFunc";

export default class UserEvents {
  public static onGetInfoUser(socket: Socket): void {
    socket.on("get_info_user", async ({ userId, type }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return;

      try {
        const client = await getMongoClient();
        const db: Db = client.db("users");
        const collection = db.collection<any>(String(userId));

        const config = await collection.findOne({ _id: "config" });

        if (!config) {
          return Helpers.fail(socket, "get_info_user_return", type);
        }

        socket.emit("get_info_user_return", {
          code: 1,
          user: TransforUser.transformUserData(config),
          type,
        });

      } catch (err) {
        Helpers.fail(socket, "get_info_user_return", type, { error: "server_error" });
      }
    });
  }

  public static onGetInfoUsers(socket: Socket): void {
    socket.on("get_info_users", async ({ users, type }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return;

      try {
        const client = await getMongoClient();
        const db: Db = client.db("users");

        const result: Record<string, unknown> = {};

        for (const userId of users) {
          const collection = db.collection<any>(String(userId));
          const config = await collection.findOne({ _id: "config" });

          if (config?.avatar) {
            result[userId] = {
              avatar: config.avatar,
              name: config.name,
              desc: config.desc,
              id: config.id,
            };
          }
        }

        socket.emit("get_info_users_return", {
          code: 1,
          users: result,
          type,
        });

      } catch (err) {
        console.error("get_info_users error:", err);

        Helpers.fail(socket, "get_info_users_return", type, {
          error: "server_error",
        });
      }
    });
  }

  public static onGetPubKey(socket: Socket): void {
    socket.on("get_pub_key", () => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return;

      try {
        const key = fs.readFileSync(`keys/${auth.userId}/public.pem`, "utf-8");

        socket.emit("get_pub_key_return", {
          code: 1,
          key,
        });

      } catch (err) {
        socket.emit("get_pub_key_return", {
          code: 0,
          error: "server_error",
        });
      }
    });
  }

  public static onGetSelf(socket: Socket): void {
    socket.on("get_info_self", async ({ data, type, key }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return;

      try {
        let decrypted = await CryptoFunc.decryptionMsg(data);
        decrypted = safeParseJSON(decrypted);

        const client = await getMongoClient();
        const db = client.db("users");
        const collection = db.collection<any>(String(socket.data.userId));

        const config = await collection.findOne({ _id: "config" });

        if (!config) {
          return Helpers.fail(socket, "get_info_self", decrypted?.type || type);
        }

        const payload = {
          code: 1,
          user: TransforUser.transformUserDataSelf(config),
          type: decrypted.type,
        };

        const encryptedResponse = await CryptoFunc.encryptionMsg(
          key,
          JSON.stringify(payload)
        );

        socket.emit("get_info_self", {
          code: 1,
          data: encryptedResponse,
        });

      } catch (err) {
        Helpers.fail(socket, "get_info_self", type, { error: "server_error" });
      }
    });
  }

  public static onSaveProfile(socket: Socket): void {
    socket.on("save_profile", async ({ data, type }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth) return;

      try {
        let decrypted = await CryptoFunc.decryptionMsg(data);
        decrypted = safeParseJSON(decrypted);

        const { id, data: profile } = decrypted;

        const client = await getMongoClient();
        const db = client.db("users");
        const collection = db.collection<any>(String(id));

        const update: any = {
          name: profile.name,
          desc: profile.desc,
        };

        if (profile.avatar !== null) {
          update.avatar = await uploadAvatar(profile.avatar);
        }

        const result = await collection.updateOne(
          { _id: "config" },
          { $set: update }
        );

        socket.emit("save_profile", {
          code: result.modifiedCount ? 1 : 0,
        });

      } catch (err) {
        console.error("Error saving profile:", err);
        socket.emit("save_profile", { code: 0 });
      }
    });
  }
}