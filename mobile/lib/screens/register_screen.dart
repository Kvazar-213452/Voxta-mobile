import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/crypto/crypto_app.dart';
import '../utils/crypto/utils.dart';
import '../models/storage_key.dart';
import '../config.dart';
import 'widgets/login/login_background.dart';
import 'widgets/login/login_panel.dart';
import 'widgets/login/custom_input_field.dart';
import 'verification_screen.dart';
import '../app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginBackground(
        child: LoginPanel(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Реєстрація',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandGreen,
                  ),
                ),
                const SizedBox(height: 30),
                CustomInputField(
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
                CustomInputField(
                  controller: _emailController,
                  label: 'Email',
                  placeholder: 'Введіть email',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введіть email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomInputField(
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
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: AppColors.blackText,
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
                    Text(
                      'Вже є акаунт? ',
                      style: TextStyle(fontSize: 13, color: AppColors.grayText),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Увійти',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.brandGreen,
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
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;

      try {
        final keyPair = await getOrCreateKeyPair();
        final publicKeyPem = encodePublicKeyToPemPKCS1(keyPair.publicKey);

        final dataToEncrypt = jsonEncode({'gmail': email});

        final serverPublicKeyPem = await getServerPublicKey();

        final encrypted = await encryptMessage(
          dataToEncrypt,
          serverPublicKeyPem,
        );

        final response = await http.post(
          Uri.parse('${Config.URL_SERVICES_AUNTIFICATION}/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'data': {'data': encrypted['data'], 'key': encrypted['key']},
            'key': publicKeyPem,
            'type': 'mobile',
          }),
        );

        final jsonResponse = jsonDecode(response.body);
        final decrypted = await decryptServerResponse(
          jsonResponse,
          keyPair.privateKey,
        );

        final data = jsonDecode(decrypted);

        if (jsonResponse['code'] == 1) {
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => VerificationScreen(
                    name: name,
                    email: email,
                    password: password,
                    codeJwt: data["codeJwt"]
                  ),
            ),
          );
        } else {
          // Інша логіка, якщо потрібно
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Помилка: ${jsonResponse['message'] ?? 'Невідома помилка'}',
              ),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка реєстрації: $e')));
        print(e);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
