import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/crypto/crypto_app.dart';
import '../utils/crypto/utils.dart';
import '../models/storage_key.dart';
import '../screens/main_screen.dart';
import '../config.dart';
import '../models/storage_user.dart';
import '../models/interface/user.dart';
import 'widgets/login/login_background.dart';
import 'widgets/login/login_panel.dart';
import 'widgets/login/login_form.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginBackground(
        child: LoginPanel(
          child: LoginForm(
            formKey: _formKey,
            nameController: _nameController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            onSubmit: _handleLogin,
          ),
        ),
      ),
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

        final serverPublicKeyPem = await getServerPublicKey();

        final encrypted = await encryptMessage(dataToEncrypt, serverPublicKeyPem);

        final response = await http.post(
          Uri.parse('${Config.URL_SERVICES_AUNTIFICATION}/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'data': {
              'data': encrypted['data'],
              'key': encrypted['key'],
            },
            'key': publicKeyPem,
            'type': 'mobile',
          }),
        );

        final jsonResponse = jsonDecode(response.body);
        final decrypted = await decryptServerResponse(jsonResponse, keyPair.privateKey);

        final data = jsonDecode(decrypted);
        final dataJsonMap = jsonDecode(data['user']);
        final userModel = UserModel.fromJson(dataJsonMap);

        await saveJWTStorage(data["token"]);
        await saveUserStorage(userModel);

        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );

                  print(e);
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