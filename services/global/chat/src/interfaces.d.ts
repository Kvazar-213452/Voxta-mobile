// ======= golobal =======
declare interface Chat {
  name: string;
  description: string;
  privacy: string;
  avatar: string | null;
  createdAt: string;
}

declare interface Message {
  id: string; 
  sender: string; 
  content: string; 
  time: string
}

declare interface MessageNoneId {
  sender: string; 
  content: string; 
  time: string
}
