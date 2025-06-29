import 'package:flutter/material.dart';
import '../config.dart';

class PixelButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const PixelButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = PixelColors.buttonBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: backgroundColor,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}