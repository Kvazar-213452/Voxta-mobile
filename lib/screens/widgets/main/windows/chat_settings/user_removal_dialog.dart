import 'package:flutter/material.dart';
import '../../../../../app_colors.dart';

class UserRemovalDialog extends StatelessWidget {
  final String userId;
  final String userName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const UserRemovalDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientMiddle,
              AppColors.gradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.warningRed.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.warningRed.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.blackText.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.warningRed.withOpacity(0.2),
                    AppColors.warningRedLight.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.warningRed.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppColors.warningRed,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Підтвердити видалення',
              style: TextStyle(
                color: AppColors.lightGray,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.grayText,
                  fontSize: 16,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Ви дійсно хочете видалити користувача\n'),
                  TextSpan(
                    text: userName,
                    style: TextStyle(
                      color: AppColors.brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' з чату?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warningRed.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Ця дія незворотна',
                style: TextStyle(
                  color: AppColors.warningRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.whiteTransparent08,
                      foregroundColor: AppColors.grayText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.whiteText.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Скасувати',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm, // Тепер викликаємо callback безпосередньо
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.warningRed,
                      foregroundColor: AppColors.whiteText,
                      elevation: 0,
                      shadowColor: AppColors.warningRed.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Видалити',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String userId,
    required String userName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.dialogOverlay,
      builder: (BuildContext context) {
        return UserRemovalDialog(
          userId: userId,
          userName: userName,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );
  }
}