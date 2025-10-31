// ======= golobal =======
declare interface UserConfig {
  _id: string;
  name: string;
  password: string;
  time: string;
  avatar: string;
  desc: string;
  chats: string[];
  id: string;
}

declare interface JWTDocument {
  _id: string;
  token: string[];
}

declare interface User {
  id: string;
  name: string;
  password: string;
  time: string;
  avatar: string;
  desc: string;
  chats: string[];
}

declare interface LoginData {
  name: string;
  password: string;
}

declare interface RegisterData {
  name: string;
  password: string;
  gmail: string;
}

declare interface EncryptedData {
  key: string;
  data: string;
}
