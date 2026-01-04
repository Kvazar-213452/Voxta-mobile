const http = require('http');
const { Server } = require('socket.io');
const { io: ClientIO } = require('socket.io-client');

const TARGET_WS = 'ws://prem-eu3.bot-hosting.net:20414';
const PORT = 3000;

const server = http.createServer();

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: true
  },
  transports: ['websocket']
});

io.on('connection', (clientSocket) => {
  console.log('Client connected:', clientSocket.id);

  const targetSocket = ClientIO(TARGET_WS, {
    transports: ['websocket'],
    reconnection: true,
    reconnectionAttempts: 3,
    reconnectionDelay: 2000,
    timeout: 10000
  });

  targetSocket.on('connect', () => {
    console.log('✅ Connected to target WS server');
  });

  targetSocket.on('connect_error', (err) => {
    console.error('Connection error to target WS:', err.message);
    targetSocket.disconnect();
  });

  targetSocket.on('disconnect', (reason) => {
    console.log('Target WS server disconnected:', reason);
  });

  clientSocket.onAny((event, ...args) => {
    if (targetSocket.connected) {
      targetSocket.emit(event, ...args);
    }
  });

  targetSocket.onAny((event, ...args) => {
    clientSocket.emit(event, ...args);
  });

  clientSocket.on('disconnect', () => {
    console.log('Client disconnected:', clientSocket.id);
    targetSocket.disconnect();
  });
});

server.listen(PORT, () => {
  console.log(`WS Proxy running on port ${PORT}`);
});
