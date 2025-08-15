import 'package:flutter/material.dart';
import '../../../../../services/chat/socket_service.dart';
import 'add_chat_window.dart';

class _JoinChatModal extends StatefulWidget {
  final Function(String)? onJoinChat;

  const _JoinChatModal({
    this.onJoinChat,
  });

  @override
  State<_JoinChatModal> createState() => _JoinChatModalState();
}

class _JoinChatModalState extends State<_JoinChatModal> with TickerProviderStateMixin {
  final TextEditingController _chatIdController = TextEditingController();
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
    
    _chatIdController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _chatIdController.text.trim().isNotEmpty;
    });
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _joinChat() {
    if (_isFormValid) {
      final key = _chatIdController.text.trim();

      socket!.emit('join_chat', {
        'key': key
      });
      
      if (widget.onJoinChat != null) {
        widget.onJoinChat!(key);
      }
      _closeModal();
      AddChatScreen.addChatScreenKey.currentState?.closeScreen();
      loadChats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2D2D32),
                        Color(0xFF232338),
                        Color(0xFF1F1F1F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF58FF7F).withOpacity(0.3),
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
            color: Colors.white.withOpacity(0.1),
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
              color: const Color(0xFF58FF7F).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.login,
              color: Color(0xFF58FF7F),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              '🚪 Приєднатися до чату',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEEEEEE),
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
          const Text(
            'Введіть ID чату, до якого хочете приєднатися:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _chatIdController,
            label: 'ID Чату',
            hint: 'Введіть ID чату...',
            icon: Icons.chat_bubble_outline,
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(
            color: Color(0xFFEEEEEE),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF58FF7F).withOpacity(0.7),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0x1AFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF58FF7F),
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
            color: Colors.white.withOpacity(0.1),
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
                backgroundColor: const Color(0x1AFFFFFF),
                foregroundColor: const Color(0xFFEEEEEE),
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
              onPressed: _isFormValid ? _joinChat : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58FF7F),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF58FF7F).withOpacity(0.3),
                disabledForegroundColor: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: _isFormValid ? 4 : 0,
              ),
              child: const Text(
                'Приєднатися',
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

class ChatFooter extends StatelessWidget {
  final VoidCallback? onCreate;
  final bool isFormValid;
  final Function(String)? onJoinChat;

  const ChatFooter({
    super.key,
    required this.onCreate,
    required this.isFormValid,
    this.onJoinChat,
  });

  void _showJoinChatModal(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _JoinChatModal(onJoinChat: onJoinChat);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => _showJoinChatModal(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0x1AFFFFFF),
                foregroundColor: const Color(0xFFEEEEEE),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Приєднатися',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isFormValid ? onCreate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58FF7F),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF58FF7F).withOpacity(0.3),
                disabledForegroundColor: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isFormValid ? 4 : 0,
              ),
              child: const Text(
                'Створити чат',
                style: TextStyle(
                  fontSize: 16,
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

// join