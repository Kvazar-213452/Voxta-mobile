import 'package:flutter/material.dart';

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
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D2D32),
              Color(0xFF232338),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF5555).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5555).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Іконка попередження
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF5555).withOpacity(0.2),
                    const Color(0xFFFF3333).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFFF5555).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFFF5555),
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            
            // Заголовок
            const Text(
              'Підтвердити видалення',
              style: TextStyle(
                color: Color(0xFFEEEEEE),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Опис
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 16,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Ви дійсно хочете видалити користувача\n'),
                  TextSpan(
                    text: userName,
                    style: const TextStyle(
                      color: Color(0xFF58FF7F),
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
                color: const Color(0xFFFF5555).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF5555).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Text(
                'Ця дія незворотна',
                style: TextStyle(
                  color: Color(0xFFFF5555),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Кнопки
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel, // Тепер викликаємо callback безпосередньо
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: const Color(0xFFAAAAAA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.1),
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
                      backgroundColor: const Color(0xFFFF5555),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: const Color(0xFFFF5555).withOpacity(0.3),
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
      barrierColor: Colors.black87.withOpacity(0.8),
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