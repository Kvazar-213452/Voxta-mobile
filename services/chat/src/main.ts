import http from 'http';
import { Server, Socket } from 'socket.io';
import { loadConfig, rebuildConfig, CONFIG } from "./utils/config/config";
import { setIO } from "./utils/config/io";
import fs from "fs";
import path from "path";

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
import { onNewChatCreateServer } from './socketEvents/chat/onNewChatCreateServer';
import { onGetSelf } from './socketEvents/user/onGetSelf';
import { onSaveProfile } from './socketEvents/user/onSaveProfile';
import { onCreateTemporaryChat } from './socketEvents/chat/onCreateTemporaryChat';
import { onGetInfoChatFix } from './socketEvents/chat/onGetInfoChatFix';
import { onDelChat } from './socketEvents/chat/onDelChat';
import { onGetPubKey } from './socketEvents/user/onGetPubKey';

import { onDelSelfInChat } from './socketEvents/chat/onDelSelfInChat';
import { onDelMsg } from './socketEvents/chat/onDelMsg';

import { onGetKeyChat } from './socketEvents/chat/key/onGetKeyChat';
import { onDelKeyChat } from './socketEvents/chat/key/onDelKeyChat';
import { onGenerateKeyChat } from './socketEvents/chat/key/onGenerateKeyChat';
import { onJoinChat } from './socketEvents/chat/key/onJoinChat';

async function startServer() {
  await loadConfig("GLOBAL_URL");
  await loadConfig("GLOBAL_DB");
  await loadConfig();

  rebuildConfig();

  const dir = path.join(process.cwd(), "keys");

  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }

  const socketServer = http.createServer();
  const io = new Server(socketServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  setIO(io);

  io.on('connection', (socket: Socket) => {
    console.log(`connect client: ${socket.id}`);

    onGetPubKey(socket);
    onDelChat(socket);
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

  socketServer.listen(CONFIG.PORT, CONFIG.API, () => {
    console.log(`Socket.IO start на http://${CONFIG.API}:${CONFIG.PORT}`);
  });

  io.engine.on('connection_error', (error) => {
    console.error('Socket.IO error:', error);
  });
}

startServer().catch((err) => {
  console.error("омилка під час старту сервера:", err);
});