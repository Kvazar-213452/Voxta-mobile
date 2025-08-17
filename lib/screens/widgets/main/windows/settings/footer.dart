import 'package:flutter/material.dart';
import '../../../../../app_colors.dart';

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
            color: AppColors.whiteTransparent10,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterButton(
              text: 'Вихід',
              color: AppColors.errorRedTransparent20,
              textColor: AppColors.errorRedLight,
              onTap: onLogout,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFooterButton(
              text: 'Скинути',
              color: AppColors.whiteTransparent10,
              textColor: AppColors.whiteText,
              onTap: onReset,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFooterButton(
              text: 'Зберегти',
              color: AppColors.brandGreen,
              textColor: AppColors.blackText,
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
            color: AppColors.whiteTransparent10,
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