import http from 'http';
import { Server, Socket } from 'socket.io';
import { loadConfig, rebuildConfig, CONFIG } from "./utils/config/config";
import { setIO } from "./utils/config/io";
import fs from "fs";
import path from "path";
import CreateEvents from './socketEvents/chatEvents/onCreate';
import DelEvents from './socketEvents/chatEvents/onDel';
import GetEvents from './socketEvents/chatEvents/onGet';
import KeyChat from './socketEvents/chatEvents/onKeyChat';
import UserEvents from './socketEvents/userEvents';
import ServerEvents from './socketEvents/serverEvents';

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
    maxHttpBufferSize: 100 * 1024 * 1024,
  });

  setIO(io);

  io.on('connection', (socket: Socket) => {
    console.log(`connect client: ${socket.id}`);

    UserEvents.onGetPubKey(socket);
    DelEvents.onDelChat(socket);
    GetEvents.onGetInfoChatFix(socket);
    CreateEvents.onCreateTemporaryChat(socket);
    DelEvents.onDelMsg(socket);
    DelEvents.onDelSelfInChat(socket);
    UserEvents.onSaveProfile(socket);
    KeyChat.onJoinChat(socket);
    KeyChat.onGenerateKeyChat(socket);
    KeyChat.onDelKeyChat(socket);
    KeyChat.onGetKeyChat(socket);
    UserEvents.onGetSelf(socket);
    CreateEvents.onNewChatCreateServer(socket);
    ServerEvents.onAuthenticate(socket);
    GetEvents.onGetInfoChats(socket);
    GetEvents.onLoadChatContent(socket);
    CreateEvents.onSendMessage(socket);
    CreateEvents.onCreateChat(socket);
    UserEvents.onGetInfoUsers(socket);
    UserEvents.onGetInfoUser(socket);
    GetEvents.onGetInfoChat(socket);
    CreateEvents.onAddUserInChat(socket);
    DelEvents.onDelMemberInChat(socket);
    CreateEvents.onSaveSettingsChat(socket);
    ServerEvents.onDisconnect(socket);
    ServerEvents.onError(socket);
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