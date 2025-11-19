import { Socket } from "socket.io";
import { verifyAuth } from "../utils/verifyAuth";

export default class Helpers {
  public static fail(socket: Socket, event: string, type: string, extra: object = {}) {
    socket.emit(event, { code: 0, type, ...extra });
  }

  public static getAuthOrFail(socket: Socket) {
    const auth = verifyAuth(socket);
    return auth || null;
  }
}