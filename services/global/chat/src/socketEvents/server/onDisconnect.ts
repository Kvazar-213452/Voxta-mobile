import { Socket } from "socket.io";
import { removeServer } from '../../utils/serverChats';

export function onDisconnect(socket: Socket): void {
  socket.on("disconnect", () => {
    socket.data.typeUser === 'ASO' && removeServer(socket.id);

    console.log("client disconnect", socket.id);
  });
}
