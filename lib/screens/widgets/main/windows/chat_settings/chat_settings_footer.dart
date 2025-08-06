import 'package:flutter/material.dart';

class ChatSettingsFooter extends StatelessWidget {
  final bool isFormValid;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ChatSettingsFooter({
    super.key,
    required this.isFormValid,
    required this.onCancel,
    required this.onSave,
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Скасувати',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isFormValid ? onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58FF7F),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF58FF7F).withOpacity(0.3),
                disabledForegroundColor: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: isFormValid ? 4 : 0,
              ),
              child: const Text(
                'Зберегти',
                style: TextStyle(
                  fontSize: 15,
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