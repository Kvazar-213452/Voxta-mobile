import 'package:flutter/material.dart';

class ChatFooter extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onCreate;
  final bool isFormValid;

  const ChatFooter({
    super.key,
    required this.onCancel,
    required this.onCreate,
    required this.isFormValid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0x1AFFFFFF),
                foregroundColor: const Color(0xFFEEEEEE),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Скасувати',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isFormValid ? onCreate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58FF7F),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF58FF7F).withOpacity(0.3),
                disabledForegroundColor: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isFormValid ? 4 : 0,
              ),
              child: const Text(
                'Створити чат',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}