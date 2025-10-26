import { Socket } from "socket.io";

export function onError(socket: Socket): void {
  socket.on("error", (error) => {
    console.error("error:", error);
  });
}
