import { Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { getMongoClient } from '../../models/mongoClient';
import { Db } from 'mongodb';
import { CONFIG } from '../../utils/config/config'
import { transforUser } from '../../utils/transform'
import { decryptionMsg, encryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";

import axios from "axios";
import fs from "fs";
import path from "path";

export function onAuthenticate(socket: Socket): void {
  socket.on('authenticate', async (data: { data: any, type: string, key: string }) => {

    let dataDec: any;
    dataDec = await decryptionMsg(data.data);
    dataDec = safeParseJSON(dataDec);

    try {
      const decoded = jwt.verify(dataDec.token, CONFIG.SECRET_KEY) as { userId: string };

      console.log(`user ${decoded.userId} authenticated.`);
      socket.data.userId = decoded.userId;
      socket.data.token = dataDec.token;
      socket.data.typeUser = 'user';

      const client = await getMongoClient();
      const db: Db = client.db('users');
      const collection = db.collection<any>(decoded.userId);

      let userConfig = await collection.findOne({ _id: 'config' });

      if (!userConfig) {
        socket.emit('authenticated', { code: 0 });
        socket.disconnect();
        return;
      }

      const userKeyDir = path.join("keys", decoded.userId);

      if (!fs.existsSync(userKeyDir)) {
        fs.mkdirSync(userKeyDir, { recursive: true });
      }

      const resp = await axios.post(`${CONFIG.MICROSERVICES_CRYPTO}generate`);
      const { publicKey, privateKey } = resp.data.result;

      fs.writeFileSync(path.join(userKeyDir, "public.pem"), publicKey);
      fs.writeFileSync(path.join(userKeyDir, "private.pem"), privateKey);

      console.log("Keys saved for user:", decoded.userId);

      userConfig._id = userConfig.id;
      delete userConfig.id;

      const dataCtypto = {
        code: 1,
        user: transforUser(userConfig)
      };

      socket.emit('authenticated', {
        data: await encryptionMsg(data.key, JSON.stringify(dataCtypto))
      });

    } catch (error) {
      console.log("AUTH ERROR:", error);
      socket.emit('authenticated', { code: 0 });
      socket.disconnect();
    }
  });
}
