import { Socket } from "socket.io";

export function onDisconnect(socket: Socket): void {
  socket.on("disconnect", () => {
    console.log("client disconnect", socket.id);
  });
}
