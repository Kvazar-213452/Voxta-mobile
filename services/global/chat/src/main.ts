import express from 'express';
import http from 'http';
import { Server, Socket } from 'socket.io';
import dotenv from 'dotenv';
import { onGetInfoChats } from './socketEvents/chat/onGetInfoChats';
import { onLoadChatContent } from './socketEvents/chat/onLoadChatContent';
import { onSendMessage } from './socketEvents/chat/onSendMessage';
import { onAuthenticate } from './socketEvents/server/onAuthenticate';
import { onDisconnect } from './socketEvents/server/onDisconnect';
import { onError } from './socketEvents/server/onError';
import { onCreateChat } from './socketEvents/chat/onCreateChat';
import { onGetInfoUsers } from './socketEvents/user/onGetInfoUsers';
import { onGetInfoUser } from './socketEvents/user/onGetInfoUser';
import { onGetInfoChat } from './socketEvents/chat/onGetInfoChat';
import { onAddUserInChat } from './socketEvents/chat/onAddUserInChat';
import { onDelMemberInChat } from './socketEvents/chat/onDelMemberInChat';
import { onSaveSettingsChat } from './socketEvents/chat/onSaveSettingsChat';
import { onCreateChatServer } from './socketEvents/chat/onCreateChatServer';
import { onNewChatCreateServer } from './socketEvents/chat/onNewChatCreateServer';
import { onUpdataChatServer } from './socketEvents/server/onUpdataChatServer';
import { onGetSelf } from './socketEvents/user/onGetSelf';
import { onSaveProfile } from './socketEvents/user/onSaveProfile';
import { onCreateTemporaryChat } from './socketEvents/chat/onCreateTemporaryChat';
import { onGetInfoChatFix } from './socketEvents/chat/onGetInfoChatFix';

import { onDelSelfInChat } from './socketEvents/chat/onDelSelfInChat';
import { onDelMsg } from './socketEvents/chat/onDelMsg';

import { onGetKeyChat } from './socketEvents/chat/key/onGetKeyChat';
import { onDelKeyChat } from './socketEvents/chat/key/onDelKeyChat';
import { onGenerateKeyChat } from './socketEvents/chat/key/onGenerateKeyChat';
import { onJoinChat } from './socketEvents/chat/key/onJoinChat';

dotenv.config();

const EXPRESS_PORT = parseInt(process.env.PORT_SERVER || '3000');
const SOCKET_PORT = parseInt(process.env.PORT || '3001');
export const SECRET_KEY = process.env.SECRET_KEY ?? 'default-secret-key';

// ------------------------
// EXPRESS SERVER
// ------------------------
const app = express();

app.listen(EXPRESS_PORT, () => {
  console.log(`Express API запущено на http://localhost:${EXPRESS_PORT}`);
});

// ------------------------
// SOCKET.IO SERVER
// ------------------------
const socketServer = http.createServer();
const io = new Server(socketServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

io.on('connection', (socket: Socket) => {
  console.log(`conect client: ${socket.id}`);

  onGetInfoChatFix(socket);
  onCreateTemporaryChat(socket);
  onDelMsg(socket);
  onDelSelfInChat(socket);
  onSaveProfile(socket);
  onJoinChat(socket);
  onGenerateKeyChat(socket);
  onDelKeyChat(socket);
  onGetKeyChat(socket);
  onGetSelf(socket);
  onGetSelf(socket);
  onUpdataChatServer(socket);
  onCreateChatServer(socket);
  onNewChatCreateServer(socket);
  onAuthenticate(socket);
  onGetInfoChats(socket);
  onLoadChatContent(socket);
  onSendMessage(socket);
  onCreateChat(socket);
  onGetInfoUsers(socket);
  onGetInfoUser(socket);
  onGetInfoChat(socket);
  onAddUserInChat(socket);
  onDelMemberInChat(socket);
  onSaveSettingsChat(socket);
  onDisconnect(socket);
  onError(socket);
});

export function getIO(): Server {
  return io;
}

socketServer.listen(SOCKET_PORT, '0.0.0.0', () => {
  console.log(`Socket.IO start на http://localhost:${SOCKET_PORT}`);
});

io.engine.on('connection_error', (error) => {
  console.error('Socket.IO error:', error);
});
