import 'package:flutter/material.dart';
import '../../../../../app_colors.dart';

class SettingsHeaderWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const SettingsHeaderWidget({
    super.key,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.whiteTransparent10,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackPressed,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.whiteTransparent10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.whiteText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            '⚙️ Налаштування',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.whiteText,
            ),
          ),
        ],
      ),
    );
  }
}