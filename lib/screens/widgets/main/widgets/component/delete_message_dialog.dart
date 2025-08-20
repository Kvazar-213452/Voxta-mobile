import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../../models/interface/chat_models.dart';
import '../../../../../app_colors.dart';
import '../utils/del_msg.dart';

class DeleteMessageDialog {
  static void show({
    required BuildContext context,
    required Message message,
    required String chatId,
    VoidCallback? onDelete,
  }) {
    showGeneralDialog(
      context: context,
      barrierColor: AppColors.overlayBlack50,
      barrierDismissible: true,
      barrierLabel: 'Delete Message',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _DeleteMessageDialogWidget(
          message: message,
          chatId: chatId,
          onDelete: onDelete,
          animation: animation,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _DeleteMessageDialogWidget extends StatelessWidget {
  final Message message;
  final String chatId;
  final VoidCallback? onDelete;
  final Animation<double> animation;

  const _DeleteMessageDialogWidget({
    required this.message,
    required this.chatId,
    this.onDelete,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlack30,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.whiteTransparent10,
                    AppColors.whiteTransparent05,
                  ],
                ),
                border: Border.all(
                  color: AppColors.whiteTransparent20,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Іконка з анімацією
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.warningRedTransparent10,
                                  AppColors.errorRedTransparent20,
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.warningRed.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 36,
                              color: AppColors.warningRed,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Заголовок
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - animation.value)),
                          child: Opacity(
                            opacity: animation.value,
                            child: Text(
                              'Видалити повідомлення?',
                              style: TextStyle(
                                color: AppColors.whiteText,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                decoration: TextDecoration.none, // Вимикає підкреслення
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Опис
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - animation.value)),
                          child: Opacity(
                            opacity: animation.value,
                            child: Text(
                              'Це повідомлення буде видалено назавжди і не може бути відновлено.',
                              style: TextStyle(
                                color: AppColors.whiteTransparent60,
                                fontSize: 16,
                                height: 1.4,
                                decoration: TextDecoration.none, // Вимикає підкреслення
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Кнопки
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 40 * (1 - animation.value)),
                          child: Opacity(
                            opacity: animation.value,
                            child: Column(
                              children: [
                                // Кнопка видалення
                                _buildActionButton(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    delMsg(message.id, chatId);
                                    onDelete?.call();
                                  },
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.warningRed,
                                      AppColors.warningRedLight,
                                    ],
                                  ),
                                  borderColor: AppColors.warningRed.withOpacity(0.3),
                                  child: Text(
                                    'Видалити',
                                    style: TextStyle(
                                      color: AppColors.whiteText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none, // Вимикає підкреслення
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Кнопка скасування
                                _buildActionButton(
                                  onTap: () => Navigator.of(context).pop(),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.whiteTransparent10,
                                      AppColors.whiteTransparent05,
                                    ],
                                  ),
                                  borderColor: AppColors.whiteTransparent30,
                                  child: Text(
                                    'Скасувати',
                                    style: TextStyle(
                                      color: AppColors.whiteTransparent50,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.none, // Вимикає підкреслення
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required Gradient gradient,
    required Color borderColor,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlack30,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}