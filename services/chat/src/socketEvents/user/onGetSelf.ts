import { Socket } from 'socket.io';
import { getMongoClient } from '../../models/mongoClient';
import { verifyAuth } from '../../utils/verifyAuth';
import { Db } from 'mongodb';
import { decryptionMsg, encryptionMsg } from "../../utils/cryptoFunc";
import { safeParseJSON } from "../../utils/utils";

export function onGetSelf(socket: Socket): void {
  socket.on('get_info_self', async (data: { data: any, type: string, key: string  }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      let dataDec: any = await decryptionMsg(data.data);
      dataDec = safeParseJSON(dataDec);

      const client = await getMongoClient();
      const db: Db = client.db('users');
      const collection = db.collection<any>(socket.data.userId);

      const userConfig = await collection.findOne({ _id: 'config' });

      if (!userConfig) {
        socket.emit('get_info_self', { 
          code: 0,
          type: dataDec.type
        });
        return;
      }

      const messageToInsert = {
        code: 1,
        user: transformUserData(userConfig),
        type: dataDec.type
      };

      socket.emit('get_info_self', {
        code: 1,
        data: await encryptionMsg(data.key, JSON.stringify(messageToInsert))
      });

    } catch (error) {
      socket.emit('get_info_self', {
        code: 0,
        error: 'server_error',
        type: data.type
      });
    }
  });
}

function transformUserData(user: Record<string, any>): Record<string, any> {
  return {
    avatar: user.avatar,
    desc: user.desc,
    name: user.name,
    id: user.id,
    time: user.time,
    password: user.password,
    chats: user.chats
  };
}
