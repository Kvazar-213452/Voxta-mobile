import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/cripto_app.dart';
import '../module/storage_app.dart';
import '../screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const Color primaryColor = Color(0xFF58FF7F);
  static const Color textLight = Color(0xFFEEEEEE);
  static const Color textMuted = Color(0xFFAAAAAA);
  static const Color inputBg = Color(0x1AFFFFFF);
  static const Color panelBg = Color(0x14FFFFFF);
  static const Color glowColor = Color(0xC758FF7F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F1F1F),
              Color(0xFF2D2D32),
              Color(0xFF232338),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: MediaQuery.of(context).size.width * 0.6,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 350,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: inputBg,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Вхід в акаунт',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildInputField(
                          controller: _nameController,
                          label: 'Ім\'я користувача',
                          placeholder: 'Введіть ім\'я',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введіть ім\'я користувача';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _passwordController,
                          label: 'Пароль',
                          placeholder: 'Введіть пароль',
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введіть пароль';
                            }
                            if (value.length < 6) {
                              return 'Пароль має бути не менше 6 символів';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _confirmPasswordController,
                          label: 'Пароль повторити',
                          placeholder: 'Введіть пароль повторити',
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Підтвердіть пароль';
                            }
                            if (value != _passwordController.text) {
                              return 'Паролі не співпадають';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Зареєструватися',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Вже є акаунт? ',
                              style: TextStyle(fontSize: 13, color: textMuted),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Тут можна зробити навігацію
                              },
                              child: const Text(
                                'Зарегеструватись',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              color: textMuted,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          style: const TextStyle(
            color: textLight,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryColor, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

void _handleLogin() async {
  if (_formKey.currentState!.validate()) {
    final name = _nameController.text;
    final password = _passwordController.text;

    try {
      final keyPair = await getOrCreateKeyPair();
      final publicKeyPem = encodePublicKeyToPemPKCS1(keyPair.publicKey);

      final dataToEncrypt = jsonEncode({
        'name': name,
        'password': password,
      });

      // Отримуємо публічний ключ сервера
      final serverPublicKeyPem = await getServerPublicKey();
      
      // Використовуємо нову функцію encryptMessage
      final encrypted = await encryptMessage(dataToEncrypt, serverPublicKeyPem);

      final response = await http.post(
        Uri.parse('http://192.168.68.101:3000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'data': encrypted['data'], // вже готовий формат nonce.authTag.encrypted_data
            'key': encrypted['key'],   // зашифрований AES ключ
          },
          'key': publicKeyPem, // ваш публічний ключ для відповіді
          'type': 'mobile',
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      final decrypted = await decryptServerResponse(jsonResponse, keyPair.privateKey);

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(responseText: decrypted),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e')),
      );
    }
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
