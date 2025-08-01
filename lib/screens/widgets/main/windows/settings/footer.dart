import 'package:flutter/material.dart';

class SettingsFooterWidget extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const SettingsFooterWidget({
    super.key,
    required this.onLogout,
    required this.onReset,
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
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterButton(
              text: 'Вихід',
              color: Colors.red.withOpacity(0.2),
              textColor: Colors.red.shade300,
              onTap: onLogout,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFooterButton(
              text: 'Скинути',
              color: Colors.white.withOpacity(0.1),
              textColor: Colors.white,
              onTap: onReset,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFooterButton(
              text: 'Зберегти',
              color: const Color(0xFF58ff7f),
              textColor: Colors.black,
              onTap: onSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}