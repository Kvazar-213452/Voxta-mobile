import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app_colors.dart';

class TemporaryChatModal extends StatefulWidget {
  final String chatName;
  final String chatDescription;
  final String privacy;
  final String avatarBase64;
  final Function(
    String chatName,
    String privacy,
    String avatarBase64,
    String chatDescription,
    int expirationHours,
    String password,
  )
  onCreateTemporary;

  const TemporaryChatModal({
    super.key,
    required this.chatName,
    required this.chatDescription,
    required this.privacy,
    required this.avatarBase64,
    required this.onCreateTemporary,
  });

  @override
  State<TemporaryChatModal> createState() => _TemporaryChatModalState();
}

class _TemporaryChatModalState extends State<TemporaryChatModal>
    with TickerProviderStateMixin {
  final TextEditingController _hoursController = TextEditingController(
    text: '6',
  );
  final TextEditingController _passwordController = TextEditingController();

  bool _isFormValid = false;
  bool _showPassword = false;

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

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _hoursController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hoursController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
      _isFormValid =
          hours > 0 &&
          hours <= 12 &&
          _passwordController.text.trim().isNotEmpty;
    });
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _createTemporaryChat() {
    if (_isFormValid) {
      final hours = int.parse(_hoursController.text.trim());
      widget.onCreateTemporary(
        widget.chatName,
        widget.privacy,
        widget.avatarBase64,
        widget.chatDescription,
        hours,
        _passwordController.text.trim(),
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
          color: Color.lerp(
            AppColors.transparent,
            AppColors.blackTransparent50,
            _fadeAnimation.value,
          ),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(maxHeight: 650),
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
                      Flexible(
                        child: SingleChildScrollView(child: _buildBody()),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.whiteTransparent10, width: 1),
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
            child: Icon(Icons.timer, color: AppColors.brandGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '⏱️ Налаштування тимчасового чату',
              style: TextStyle(
                fontSize: 18,
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
                Icon(Icons.info_outline, color: AppColors.brandGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Тимчасовий чат автоматично видалиться після закінчення часу',
                    style: TextStyle(fontSize: 13, color: AppColors.lightGray),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildHoursField(),
          const SizedBox(height: 20),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Пароль користувача',
            hint: 'Введіть пароль для входу...',
            icon: Icons.lock,
            showPassword: _showPassword,
            onToggleVisibility: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHoursField() {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final isValid = hours > 0 && hours <= 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Час існування',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _hoursController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          style: TextStyle(color: AppColors.lightGray, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Від 1 до 12 годин',
            hintStyle: TextStyle(color: AppColors.whiteTransparent50),
            suffixText: 'год',
            suffixStyle: TextStyle(
              color: AppColors.brandGreen,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.access_time,
              color:
                  isValid
                      ? AppColors.brandGreen
                      : AppColors.brandGreenTransparent07,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.transparentWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.whiteTransparent20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isValid
                        ? AppColors.brandGreenTransparent30
                        : AppColors.whiteTransparent20,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.brandGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.5),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Максимальний час існування - 12 годин',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
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
          obscureText: !showPassword,
          style: TextStyle(color: AppColors.lightGray, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.whiteTransparent50),
            prefixIcon: Icon(
              icon,
              color: AppColors.brandGreenTransparent07,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.white54,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: AppColors.transparentWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.whiteTransparent20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.whiteTransparent20),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.brandGreen, width: 2),
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
          top: BorderSide(color: AppColors.whiteTransparent10, width: 1),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isFormValid ? _createTemporaryChat : null,
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
                'Створити чат',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}