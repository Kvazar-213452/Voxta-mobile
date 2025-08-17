import 'package:flutter/material.dart';
import 'custom_input_field.dart';
import '../../../app_colors.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Вхід в акаунт',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.brandGreen,
            ),
          ),
          const SizedBox(height: 30),
          CustomInputField(
            controller: nameController,
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
            controller: passwordController,
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
          CustomInputField(
            controller: confirmPasswordController,
            label: 'Пароль повторити',
            placeholder: 'Введіть пароль повторити',
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Підтвердіть пароль';
              }
              if (value != passwordController.text) {
                return 'Паролі не співпадають';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
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
                  // Тут можна зробити навігацію
                },
                child: Text(
                  'Зарегеструватись',
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
    );
  }
}