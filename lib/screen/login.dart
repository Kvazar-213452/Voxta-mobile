import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'chat.dart';
import '../config.dart';

import '../widgets/pixel_text_field.dart';
import '../widgets/pixel_button.dart';

final storage = FlutterSecureStorage();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    final url = Uri.parse(Config.url_login);
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'name': username,
      'password': password,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List && jsonResponse.isNotEmpty) {
          final data = jsonResponse;
          final jwtToken = data[0];
          final userId = data[1]['_id'];

          await storage.write(key: 'jwt_token', value: jwtToken);
          await storage.write(key: 'user_id', value: userId);

          print('JWT токен збережено!');
          print('Користувач знайдений: $userId');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(userId: userId),
            ),
          );
        } else {
          print('Користувача не знайдено.');
        }
      } else {
        print('Помилка: ${response.statusCode}');
      }
    } catch (e) {
      print('Виникла помилка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelColors.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildLoginForm(),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Card(
      color: PixelColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PIXEL MESSENGER',
              style: TextStyle(
                color: PixelColors.accentGreen,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'LOGIN',
              style: TextStyle(
                color: PixelColors.textSecondary,
                fontSize: 16,
                letterSpacing: 1.0,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 32),
            PixelTextField(
              controller: _usernameController,
              label: 'USERNAME',
              placeholder: 'Enter username...',
            ),
            const SizedBox(height: 24),
            PixelTextField(
              controller: _passwordController,
              label: 'PASSWORD',
              placeholder: 'Enter password...',
              isPassword: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PixelButton(
                text: 'LOGIN',
                onPressed: _login,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
