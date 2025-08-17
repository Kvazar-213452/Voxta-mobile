import 'package:flutter/material.dart';

class ProfileFooterWidget extends StatelessWidget {
  final VoidCallback onSave;
  final bool isLoading;

  const ProfileFooterWidget({
    super.key,
    required this.onSave,
    this.isLoading = false,
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
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: _buildFooterButton(
              text: isLoading ? 'Збереження...' : 'Зберегти зміни',
              color: const Color(0xFF58ff7f),
              textColor: Colors.black,
              onTap: isLoading ? () {} : onSave,
              isLoading: isLoading,
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
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
        ),
      ),
    );
  }
}
