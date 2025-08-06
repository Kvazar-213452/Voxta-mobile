class MsgToDb {
  final String sender;
  final String content;
  final String time;

  MsgToDb({
    required this.sender,
    required this.content,
    required this.time,
  });
}

class Message {
  final String id;
  final String sender;
  final String content;
  final String time;

  Message({
    required this.id,
    required this.sender,
    required this.content,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    "_id": id,
    "sender": sender,
    "content": content,
    "time": time,
  };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'time': time,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      sender: map['sender'],
      content: map['content'],
      time: map['time'],
    );
  }
}
