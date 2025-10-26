import 'package:flutter/material.dart';
import '../../../../../app_colors.dart';

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
            color: AppColors.transparentWhite,
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
              color: AppColors.brandGreen,
              textColor: AppColors.blackText,
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
            color: AppColors.transparentWhite,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.blackText),
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