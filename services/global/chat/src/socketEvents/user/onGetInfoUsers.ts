import { Socket } from 'socket.io';
import { getMongoClient } from '../../models/mongoClient';
import { verifyAuth } from '../../utils/verifyAuth';
import { Db } from 'mongodb';
import { getIO } from '../../main';

export function onGetInfoUsers(socket: Socket): void {
  socket.on('get_info_users', async (data: { users: string[], type: string, server: any }) => {
    try {
      if (data.type === 'server') {
        if (data.server.type === 'load_chat') {
          
          const client = await getMongoClient();
          const db: Db = client.db('users');

          const participantsData: Record<string, {}> = {};

          for (const userId of data.users) {
            const collection = db.collection<any>(String(userId));
            const config = await collection.findOne({ _id: 'config' });

            if (config && config.avatar) {
              participantsData[userId] = {
                avatar: config.avatar,
                name: config.name
              };
            }
          }

          getIO().to(String(data.server.idUserServer)).emit("load_chat_content_return", {
            code: 1,
            chatId: data.server.chatId,
            messages: data.server.messages.reverse(),
            participants: participantsData,
            type: data.type
          });
        }
      } else {
        const auth = verifyAuth(socket);
        if (!auth) return;

        const client = await getMongoClient();
        const db: Db = client.db('users');

        const result: Record<string, {}> = {};

        for (const userId of data.users) {
          const collection = db.collection<any>(userId);
          const config = await collection.findOne({ _id: 'config' });

          if (config && config.avatar) {
            result[userId] = {
              avatar: config.avatar,
              name: config.name,
              desc: config.desc,
              id: config.id
            };
          }
        }

        socket.emit("get_info_users_return", {
          code: 1,
          users: result,
          type: data.type
        });
      }
    } catch (error) {
      console.log('get_info_users error:', error);
      
      socket.emit("get_info_users_return", {
        code: 0,
        error: 'server_error',
        type: data.type
      });
    }
  });
}
