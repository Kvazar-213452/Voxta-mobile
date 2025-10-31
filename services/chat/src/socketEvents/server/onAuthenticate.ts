import { Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { getMongoClient } from '../../models/mongoClient';
import { addServer } from '../../utils/serverChats';
import { Db } from 'mongodb';
import { CONFIG } from '../../utils/config/config'
import { transforUser } from '../../utils/transform'
import { decryptionMsg, encryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";

export function onAuthenticate(socket: Socket): void {
  socket.on('authenticate', async (data: { data: any, type: string, key: string }) => {

    let dataDec: any;
    
    if (data.data.token != "server") {
      dataDec = await decryptionMsg(data.data, data.type);
      dataDec = safeParseJSON(dataDec);
    } else {
      dataDec = data.data;
      dataDec.token = 'server';
    }

    try {
      if (dataDec.token === 'server') {
        addServer(socket.id, dataDec.chats);
        socket.data.typeUser = 'ASO';
        socket.emit('authenticated', { code: 1, id: socket.id});
        return
      }

      const decoded = jwt.verify(dataDec.token, CONFIG.SECRET_KEY) as { userId: string };

      console.log(`user ${decoded.userId} authenticated.`);
      socket.data.userId = decoded.userId;
      socket.data.token = dataDec.token;
      socket.data.typeUser = 'user';

      const client = await getMongoClient();
      const db: Db = client.db('users');
      const collection = db.collection<any>(decoded.userId);

      let userConfig = await collection.findOne({ _id: 'config' });
      userConfig._id = userConfig.id;
      delete userConfig.id;

      if (!userConfig) {
        socket.emit('authenticated', { code: 0 });
        socket.disconnect();
        return;
      }

      const dataCtypto = {
        code: 1,
        user: transforUser(userConfig)
      };

      socket.emit('authenticated', {
        data: await encryptionMsg(data.key, JSON.stringify(dataCtypto), data.type)
      });

    } catch (error) {
      socket.emit('authenticated', { code: 0 });
      socket.disconnect();
    }
  });
}
