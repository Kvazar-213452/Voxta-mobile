type ChatData = {
  id: string;
  type: string;
  avatar: string;
  participants: string[];
  name: string;
  createdAt: string;
  desc: string;
  owner: string;
};

let ChatsServers: { [serverId: string]: { [chatId: string]: ChatData } } = {};

export function addServer(id: string, chats: ChatData[]): void {
  if (!ChatsServers[id]) {
    ChatsServers[id] = {};
  }

  for (const chat of chats) {
    if (!ChatsServers[id][chat.id]) {
      ChatsServers[id][chat.id] = chat;
    }
  }
}

export function getChatsServer(chatIds: string[]): { [chatId: string]: ChatData } {
  const result: { [chatId: string]: ChatData } = {};

  for (const chatId of chatIds) {
    for (const serverId in ChatsServers) {
      if (ChatsServers[serverId][chatId]) {
        result[chatId] = ChatsServers[serverId][chatId];
        break;
      }
    }
  }

  return result;
}

export function getServerIdToChat(chatId: string): string | null {
  for (const serverId in ChatsServers) {
    if (ChatsServers[serverId]?.[chatId]) {
      return serverId;
    }
  }

  return null;
}

export function removeServer(id: string): void {
  if (ChatsServers[id]) {
    delete ChatsServers[id];
  }
}

export function updateChatServer(idserver: string, newData: any) {
  if (!ChatsServers[idserver]) {
    return;
  }

  if (!ChatsServers[idserver][newData.id]) {
    return;
  }

  ChatsServers[idserver][newData.id] = {
    ...ChatsServers[idserver][newData.id],
    ...newData
  };
}



// let ChatsServers1 = {
//   "idserver": {
//     "idchat": {
//       "id": "HY6cAuQ4Q12NLhVVOUB4j9l8",
//       "type": "server",
//       "avatar": "../data/avatars/5002bfdf-2c5d-44d9-b57a-041b041006ae.png",
//       "participants": [
//         "12345678901234"
//       ],
//       "name": "dqwqdqw",
//       "createdAt": "2025-07-19T00:12:44.530Z",
//       "desc": "dqwdqwd",
//       "owner": "12345678901234"
//     }
//   }
// }