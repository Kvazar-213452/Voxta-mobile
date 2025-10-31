export function generateId(length = 14): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let id = '';
  for (let i = 0; i < length; i++) {
    id += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return id;
}

export function transforUser(user: UserConfig): User {
  return {
    id: user._id,
    name: user.name,
    password: user.password,
    time: user.time,
    avatar: user.avatar,
    desc: user.desc,
    chats: user.chats
  };
}

export function generateSixDigitCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

export function safeParseJSON(input: any): any {
    if (typeof input === 'string') {
        try {
            return JSON.parse(input);
        } catch (e) {
            console.error("JSON parse error:", e);
            return null;
        }
    }
    return input;
}

