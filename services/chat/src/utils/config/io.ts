let globalIo = null;

export function getIO(): any {
  return globalIo;
}

export function setIO(io) {
  globalIo = io;
}