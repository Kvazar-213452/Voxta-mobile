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
import 'widgets/login/custom_input_field.dart';
import '../app_colors.dart';

class VerificationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String codeJwt;

  const VerificationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.codeJwt,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

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
                  'Підтвердження email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Код підтвердження надіслано на',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightGray,
                  ),
                ),
                const SizedBox(height: 30),
                CustomInputField(
                  controller: _codeController,
                  label: 'Код підтвердження',
                  placeholder: 'Введіть код',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введіть код підтвердження';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleVerification,
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
                      'Підтвердити',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Повернутися назад',
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
          ),
        ),
      ),
    );
  }

  void _handleVerification() async {
    if (_formKey.currentState!.validate()) {
      final code = _codeController.text;

      try {
        final keyPair = await getOrCreateKeyPair();
        final publicKeyPem = encodePublicKeyToPemPKCS1(keyPair.publicKey);

        final dataToEncrypt = jsonEncode({
          'name': widget.name,
          'password': widget.password,
          'codeJwt': widget.codeJwt,
          'code': code,
        });

        final serverPublicKeyPem = await getServerPublicKey();

        final encrypted = await encryptMessage(dataToEncrypt, serverPublicKeyPem);

        final response = await http.post(
          Uri.parse('${Config.URL_SERVICES_AUNTIFICATION}/register_verification'),
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(),
          ),
          (route) => false,
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка підтвердження: $e')),
        );
        print(e);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}