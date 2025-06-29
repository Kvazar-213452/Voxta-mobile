import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screen/login.dart';
import 'screen/chat.dart';
import 'services/api_service.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  final jwtToken = await storage.read(key: 'jwt_token');
  final userId = await storage.read(key: 'user_id');

  if (jwtToken != null && userId != null) {
    final userData = await ApiService.getInfoToJwt(
      jwtToken: jwtToken,
      userId: userId,
    );

    if (userData != null) {
      print('Дані користувача: ${userData['user']}');
    } else {
      print('Не вдалося отримати дані користувача.');
    }
  }

  runApp(PixelMessengerApp(
    initialUserId: (jwtToken != null && jwtToken.isNotEmpty) ? userId : null,
  ));
}

class PixelMessengerApp extends StatefulWidget {
  final String? initialUserId;
  const PixelMessengerApp({Key? key, this.initialUserId}) : super(key: key);

  @override
  State<PixelMessengerApp> createState() => _PixelMessengerAppState();
}

class _PixelMessengerAppState extends State<PixelMessengerApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Messenger',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: PixelColors.darkBackground,
        fontFamily: 'monospace',
      ),
      debugShowCheckedModeBanner: false,
      home: widget.initialUserId != null
          ? ChatScreen(userId: widget.initialUserId!)
          : const LoginScreen(),
    );
  }
}
