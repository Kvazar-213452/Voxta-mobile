import { Socket } from "socket.io";
import { verifyAuth } from "../../utils/verifyAuth";
import { getIO } from '../../main';

export function onCreateChatServer(socket: Socket): void {
  socket.on("create_chat_server", async (data: { chat: any }) => {
    try {
      const auth = verifyAuth(socket);
      if (!auth) return;

      getIO().to(data.chat.idServer).emit("create_chat", {
        chat: data.chat,
        from: socket.data.userId
      });

      socket.emit("create_chat_server", { code: 1 });

    } catch (error: unknown) {
      console.log("CONFIG DOC:", error);
      let errorMessage = "Unknown error";
      if (error instanceof Error) {
        errorMessage = error.message;
      }
      socket.emit("create_chat_server", { code: 0, error: errorMessage });
    }
  });
}
