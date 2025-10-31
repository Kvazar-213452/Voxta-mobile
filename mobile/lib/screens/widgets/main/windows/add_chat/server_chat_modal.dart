import 'package:flutter/material.dart';
import '../../../../../app_colors.dart';

class ServerChatModal extends StatefulWidget {
  final String chatName;
  final String chatDescription;
  final String privacy;
  final String avatarBase64;
  final Function(String chatName, String privacy, String avatarBase64, String chatDescription, String idServer, String codeServer) onCreateServer;

  const ServerChatModal({
    super.key,
    required this.chatName,
    required this.chatDescription,
    required this.privacy,
    required this.avatarBase64,
    required this.onCreateServer,
  });

  @override
  State<ServerChatModal> createState() => _ServerChatModalState();
}

class _ServerChatModalState extends State<ServerChatModal> with TickerProviderStateMixin {
  final TextEditingController _idServerController = TextEditingController();
  final TextEditingController _codeServerController = TextEditingController();
  bool _isFormValid = false;

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
    
    _idServerController.addListener(_validateForm);
    _codeServerController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _idServerController.dispose();
    _codeServerController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _idServerController.text.trim().isNotEmpty && 
                     _codeServerController.text.trim().isNotEmpty;
    });
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _createServerChat() {
    if (_isFormValid) {
      widget.onCreateServer(
        widget.chatName,
        widget.privacy,
        widget.avatarBase64,
        widget.chatDescription,
        _idServerController.text.trim(),
        _codeServerController.text.trim(),
      );
      _closeModal();
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildBody(),
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
              Icons.dns,
              color: AppColors.brandGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '⚙️ Налаштування сервера',
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

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Для створення серверного чату потрібно вказати дані сервера:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grayText,
            ),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _idServerController,
            label: 'ID Сервера',
            hint: 'Введіть ID сервера...',
            icon: Icons.tag,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _codeServerController,
            label: 'Код Сервера',
            hint: 'Введіть код сервера...',
            icon: Icons.vpn_key,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(
            color: AppColors.lightGray,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.whiteTransparent50,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.brandGreenTransparent07,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.transparentWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.whiteTransparent20,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.whiteTransparent20,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.brandGreen,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _closeModal,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.transparentWhite,
                foregroundColor: AppColors.lightGray,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Скасувати',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isFormValid ? _createServerChat : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.blackText,
                disabledBackgroundColor: AppColors.brandGreenTransparent30,
                disabledForegroundColor: AppColors.blackTransparent50,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: _isFormValid ? 4 : 0,
              ),
              child: const Text(
                'Створити сервер',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}