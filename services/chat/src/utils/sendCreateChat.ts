import { getIO } from '../utils/config/io';

export function sendCreateChat(userId: string, data: string, chatId: string) {
  getIO().sockets.sockets.forEach((socket) => {
    if (socket.data.userId === userId) {
      socket.emit("create_new_chat", { code: 1, chat: data, chatId: chatId });
    }
  });
}

export function onSendMessage(data: any) {
  getIO().sockets.sockets.forEach((socket) => {
      socket.emit("send_message_return", { code: 1, data: data  });
  });
}

