class UserModel {
  final String id;
  final String name;
  final String password;
  final String time;
  final String avatar;
  final String desc;
  final List<String> chats;

  UserModel({
    required this.id,
    required this.name,
    required this.password,
    required this.time,
    required this.avatar,
    required this.desc,
    required this.chats,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name'].toString(),
      password: json['password'].toString(),
      time: json['time'],
      avatar: json['avatar'],
      desc: json['desc'],
      chats: List<String>.from(json['chats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'time': time,
      'avatar': avatar,
      'desc': desc,
      'chats': chats,
    };
  }
}
