import 'package:flutter/material.dart';
import '../config.dart';

class PixelTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool isPassword;

  const PixelTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PixelColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(
            color: PixelColors.textPrimary,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: PixelColors.textSecondary,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
            filled: true,
            fillColor: PixelColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.0),
              borderSide: const BorderSide(
                color: PixelColors.borderColor,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.0),
              borderSide: const BorderSide(
                color: PixelColors.borderColor,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.0),
              borderSide: const BorderSide(
                color: PixelColors.accentGreen,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
          ),
        ),
      ],
    );
  }
}