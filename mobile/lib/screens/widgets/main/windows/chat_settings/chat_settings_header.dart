import 'package:flutter/material.dart';
import '../../../../../app_colors.dart';

class ChatSettingsHeader extends StatelessWidget {

  const ChatSettingsHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.whiteText.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '⚙️ Налаштування чату',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.lightGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}