import { Socket } from 'socket.io';
import { verifyAuth } from '../../utils/verifyAuth';
import fs from "fs";

export function onGetPubKey(socket: Socket): void {
  socket.on('get_pub_key', async (data: {}) => {
    try {
      
      const auth = verifyAuth(socket);
      if (!auth) return;

      const publicKey = fs.readFileSync('public_key.pem', 'utf-8');

      socket.emit('get_pub_key_return', {
        code: 1,
        key: publicKey
      });

    } catch (error) {
      socket.emit('get_pub_key_return', {
        code: 0,
        error: 'server_error'
      });
    }
  });
}
