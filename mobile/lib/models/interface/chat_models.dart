class ChatItem {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatar;
  final String type;
  final String owner;

  ChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatar,
    required this.type,
    required this.owner,
  });
}

class Message {
  final String id;
  final Object text;
  final bool isOwn;
  final String time;
  final String? senderName;
  final String? senderAvatar;
  final String? senderId;
  final String? type;

  Message({
    required this.id,
    required this.text,
    required this.isOwn,
    required this.time,
    this.senderName,
    this.senderAvatar,
    this.senderId,
    this.type,
  });
}