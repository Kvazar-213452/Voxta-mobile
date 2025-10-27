import 'package:flutter/material.dart';
import '../../../../../../../app_colors.dart';
import 'utils.dart';

class TemporaryPasswordModal extends StatefulWidget {
  final String chatId;
  final VoidCallback onClose;

  const TemporaryPasswordModal({
    super.key,
    required this.onClose,
    required this.chatId,
  });

  @override
  State<TemporaryPasswordModal> createState() => _TemporaryPasswordModalState();
}

class _TemporaryPasswordModalState extends State<TemporaryPasswordModal> with TickerProviderStateMixin {
  bool _showPassword = false;
  bool _isLoading = true;
  String? _error;
  
  Map<String, dynamic>? _chatData;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    _loadChatData();
  }

  void _loadChatData() {
    getChat(
      idChat: widget.chatId,
      onSuccess: (chatData) {
        if (mounted) {
          setState(() {
            _chatData = chatData;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
      widget.onClose();
    });
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Невідомо';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Невідомо';
    }
  }

  int _calculateRemainingHours(String? expiresAt) {
    if (expiresAt == null) return 0;
    
    try {
      final expirationDate = DateTime.parse(expiresAt);
      final now = DateTime.now();
      final difference = expirationDate.difference(now);
      return difference.inHours > 0 ? difference.inHours : 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Color.lerp(AppColors.transparent, AppColors.blackTransparent50, _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 700,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.gradientMiddle,
                        AppColors.gradientEnd,
                        AppColors.gradientStart,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.brandGreenTransparent30,
                      width: 1,
                    ),
                  ),
                  child: _isLoading 
                    ? _buildLoadingState()
                    : _error != null
                      ? _buildErrorState()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            Flexible(
                              child: SingleChildScrollView(
                                child: _buildBody(),
                              ),
                            ),
                            _buildFooter(),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.brandGreen,
          ),
          const SizedBox(height: 20),
          Text(
            'Завантаження даних...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.lightGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.brandGreen,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Помилка',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Невідома помилка',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.whiteTransparent50,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _closeModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: AppColors.blackText,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Закрити',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.whiteTransparent10,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandGreenTransparent20,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.lock_clock,
              color: AppColors.brandGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⏱️ Тимчасовий чат створено',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _chatData?['name'] ?? 'Невідомо',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final remainingHours = _calculateRemainingHours(_chatData?['expiresAt']);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandGreenTransparent20,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.brandGreenTransparent30,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.brandGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Збережіть цю інформацію. Пароль потрібен для входу в чат.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.lightGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Назва чату', _chatData?['name'] ?? 'Невідомо'),
          const SizedBox(height: 12),
          _buildInfoRow('Тип чату', _chatData?['type'] ?? 'Temporary'),
          const SizedBox(height: 12),
          _buildInfoRow('Опис', _chatData?['description'] ?? 'Без опису'),
          const SizedBox(height: 12),
          _buildInfoRow('Діє ще', '$remainingHours ${_getHoursWord(remainingHours)}'),
          const SizedBox(height: 12),
          _buildInfoRow('Створено', _formatDateTime(_chatData?['createdAt'])),
          const SizedBox(height: 12),
          _buildPasswordRow(),
        ],
      ),
    );
  }

  String _getHoursWord(int hours) {
    if (hours % 10 == 1 && hours % 100 != 11) {
      return 'година';
    } else if (hours % 10 >= 2 && hours % 10 <= 4 && (hours % 100 < 10 || hours % 100 >= 20)) {
      return 'години';
    } else {
      return 'годин';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.whiteTransparent50,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.transparentWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.whiteTransparent20,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.lightGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRow() {
    final password = _chatData?['password'] ?? '••••••••';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Пароль',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.whiteTransparent50,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.transparentWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.brandGreenTransparent30,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock,
                color: AppColors.brandGreen,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _showPassword ? password : '••••••••',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.lightGray,
                    fontWeight: FontWeight.w600,
                    letterSpacing: _showPassword ? 0 : 2,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.white54,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.whiteTransparent10,
            width: 1,
          ),
        ),
      ),
      child: ElevatedButton(
        onPressed: _closeModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: AppColors.blackText,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Зрозуміло',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}