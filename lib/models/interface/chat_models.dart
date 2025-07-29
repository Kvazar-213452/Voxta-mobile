class ChatItem {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatar;
  final bool isOnline;
  final String type;

  ChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatar,
    required this.isOnline,
    required this.type,
  });
}

// Додайте ці поля в ваш Message клас в chat_models.dart
class Message {
  final String id;
  final String text;
  final bool isOwn;
  final String time;
  final String? senderName;  // Додане поле
  final String? senderAvatar; // Додане поле
  final String? senderId;    // Додане поле

  Message({
    required this.id,
    required this.text,
    required this.isOwn,
    required this.time,
    this.senderName,
    this.senderAvatar,
    this.senderId,
  });
}