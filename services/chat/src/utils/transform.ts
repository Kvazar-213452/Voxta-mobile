export class TransforUser {
  public static transforUser(user: Record<string, any>): Record<string, any> {
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

  public static transformUserData(user: Record<string, any>): Record<string, any> {
    return {
      avatar: user.avatar,
      desc: user.desc,
      name: user.name,
      id: user.id,
      time: user.time
    };
  }

  public static transformUserDataSelf(user: Record<string, any>): Record<string, any> {
    return {
      avatar: user.avatar,
      desc: user.desc,
      name: user.name,
      id: user.id,
      time: user.time,
      password: user.password,
      chats: user.chats
    };
  }
}
