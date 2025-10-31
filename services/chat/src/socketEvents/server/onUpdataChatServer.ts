import { Socket } from 'socket.io';
import { updateChatServer } from '../../utils/serverChats';

export function onUpdataChatServer(socket: Socket): void {
  socket.on('updata_chat_server', async (data: { dataChat: string }) => {
    try {

      updateChatServer(socket.id, data.dataChat);

    } catch (error) {
      socket.emit('errro', { code: 0 });
      socket.disconnect();
    }
  });
}
