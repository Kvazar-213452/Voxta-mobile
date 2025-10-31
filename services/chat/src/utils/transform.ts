export function transforUser(user: Record<string, any>): Record<string, any> {
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
