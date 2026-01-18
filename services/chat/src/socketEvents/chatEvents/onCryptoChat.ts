import { Socket } from "socket.io";
import { getMongoClient } from "../../utils/mongoClient";
import { Db } from "mongodb";
import Helpers from "../helpers";

export default class CryptoChat {
  public static onSetIntervalForUser(socket: Socket): void {
    socket.on("set_interval_for_user", async (data: { id: string; userId: string; interval: string }) => {
        const auth = Helpers.getAuthOrFail(socket);
        if (!auth) return Helpers.fail(socket, "set_interval_for_user", "unauthorized");

        if (!/^\d+$/.test(data.interval)) {
          return Helpers.fail(
            socket,
            "set_interval_for_user",
            "interval_must_be_number"
          );
        }

        try {
          const client = await getMongoClient();
          const db: Db = client.db("chats");
          const collection = db.collection<{ _id: string;[key: string]: any }>(data.id);

          const configDoc = await collection.findOne({ _id: "config" as any });
          if (!configDoc) {
            return Helpers.fail(
              socket,
              "set_interval_for_user",
              "config_not_found"
            );
          }

          const updatePath = `crypto.${data.userId}.interval`;

          const result = await collection.updateOne(
            { _id: "config" },
            {
              $set: {
                [updatePath]: String(data.interval),
              },
            }
          );

          if (result.modifiedCount > 0) {
            socket.emit("set_interval_for_user", {
              code: 1,
              interval: data.interval,
            });
          } else {
            Helpers.fail(
              socket,
              "set_interval_for_user",
              "interval_not_updated"
            );
          }
        } catch (err) {
          console.error(err);
          Helpers.fail(socket, "set_interval_for_user", "db_error");
        }
      }
    );
  }

  public static onGetInterval(socket: Socket): void {
    socket.on("get_user_interval", async (data: { id: string; userId: string; }) => {
      const auth = Helpers.getAuthOrFail(socket);
      if (!auth)
        return Helpers.fail(socket, "get_interval_in_chat_return", "unauthorized");

      try {
        const client = await getMongoClient();
        const db: Db = client.db("chats");
        const collection = db.collection<{ _id: string;[key: string]: any }>(data.id);
        const configDoc = await collection.findOne({ _id: "config" as any });

        if (!configDoc) {
          return Helpers.fail(
            socket,
            "get_interval_in_chat_return",
            "config_not_found"
          );
        }

        socket.emit("get_interval_in_chat_return", {
          code: 1,
          interval: String(configDoc?.crypto?.[data.userId]?.interval) ?? ""
        });

      } catch (err) {
        console.error(err);
        Helpers.fail(socket, "get_interval_in_chat_return", "db_error");
      }
    }
    );
  }

  public static onSetPubKeyForUser(socket: Socket): void {
    socket.on("set_pub_key_for_user", async (data: { id: string; userId: string; key: string }) => {
        const auth = Helpers.getAuthOrFail(socket);
        if (!auth) return Helpers.fail(socket, "set_pub_key_for_user", "unauthorized");

        try {
          const client = await getMongoClient();
          const db: Db = client.db("chats");
          const collection = db.collection<{ _id: string;[key: string]: any }>(data.id);

          const configDoc = await collection.findOne({ _id: "config" as any });
          if (!configDoc) {
            return Helpers.fail(
              socket,
              "set_pub_key_for_user",
              "config_not_found"
            );
          }

          const updatePath = `crypto.${data.userId}.keyPub`;

          const result = await collection.updateOne(
            { _id: "config" },
            {
              $set: {
                [updatePath]: String(data.key),
              },
            }
          );

          if (result.modifiedCount > 0) {
            socket.emit("set_pub_key_for_user", {
              code: 1
            });
          } else {
            Helpers.fail(
              socket,
              "set_pub_key_for_user",
              "interval_not_updated"
            );
          }
        } catch (err) {
          console.error(err);
          Helpers.fail(socket, "set_pub_key_for_user", "db_error");
        }
      }
    );
  }
}