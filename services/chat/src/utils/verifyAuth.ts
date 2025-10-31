import { Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { CONFIG } from "../utils/config/config";

export function verifyAuth(socket: Socket): { userId: string } | null {
  try {
    const decoded = jwt.verify(socket.data.token, CONFIG.SECRET_KEY) as { userId: string };
    return decoded;
  } catch (err) {
    console.log(`no valid jwt from ${socket.id}`);
    socket.disconnect();
    return null;
  }
}
