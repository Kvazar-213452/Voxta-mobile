class ChatItem {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatar;
  final bool isOnline;

  ChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatar,
    required this.isOnline,
  });
}

class Message {
  final String text;
  final bool isOwn;
  final String time;

  Message({
    required this.text,
    required this.isOwn,
    required this.time,
  });
}