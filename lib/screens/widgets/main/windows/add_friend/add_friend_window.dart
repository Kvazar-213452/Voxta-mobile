import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'header.dart';
import 'footer.dart';
import '../../../../../services/chat/socket_service.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> with TickerProviderStateMixin {
  final TextEditingController _friendCodeController = TextEditingController();
  final TextEditingController _friendNameController = TextEditingController();
  
  bool _isFormValid = false;
  String _myFriendCode = 'Завантаження...';
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    
    _friendCodeController.addListener(_validateForm);
    _friendNameController.addListener(_validateForm);
    
    // Налаштування слухача для отримання коду друга
    _setupFriendCodeListener();
    
    // Запит коду друга
    _loadMyFriendCode();
  }

  void _setupFriendCodeListener() {
    // Встановлюємо callback для отримання коду друга
    setOnFriendCodeReceived((String friendCode) {
      if (mounted) {
        setState(() {
          _myFriendCode = friendCode;
        });
      }
    });
  }

  void _loadMyFriendCode() {
    getSelfFriendCode();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _friendCodeController.dispose();
    _friendNameController.dispose();
    // Очищуємо callback
    setOnFriendCodeReceived(null);
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _friendCodeController.text.trim().isNotEmpty;
    });
  }

  void _closeScreen() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _addFriend() {
    if (_isFormValid) {
      // Here you would typically call your friend addition logic
      print('Adding friend with code: ${_friendCodeController.text}');
      print('Friend name: ${_friendNameController.text}');
      
      _closeScreen();
    }
  }

  void _pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null) {
      _friendCodeController.text = data.text ?? '';
    }
  }

  void _copyMyCode() {
    if (_myFriendCode != 'Завантаження...' && _myFriendCode.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _myFriendCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Код скопійовано!'),
          backgroundColor: Color(0xFF58FF7F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: Transform.translate(
            offset: Offset(MediaQuery.of(context).size.width * _slideAnimation.value, 0),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1F1F1F),
                      Color(0xFF2D2D32),
                      Color(0xFF232338),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      FriendHeader(onBack: _closeScreen),
                      Expanded(
                        child: _buildBody(),
                      ),
                      FriendFooter(
                        onCancel: _closeScreen,
                        onAdd: _addFriend,
                        isFormValid: _isFormValid,
                      ),
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

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFriendCodeSection(),
          const SizedBox(height: 30),
          _buildMyCodeSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFriendCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Код дружби',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _friendCodeController,
                style: const TextStyle(
                  color: Color(0xFFEEEEEE),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Введіть код дружби...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0x1AFFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF58FF7F),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _pasteFromClipboard,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.content_paste,
                  color: Color(0xFF58FF7F),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Попросіть друга поділитися своїм кодом дружби',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }

  Widget _buildMyCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Мій код дружби',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF58FF7F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _myFriendCode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _myFriendCode == 'Завантаження...' 
                        ? const Color(0xFFAAAAAA) 
                        : const Color(0xFF58FF7F),
                    letterSpacing: _myFriendCode == 'Завантаження...' ? 0 : 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _copyMyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF58FF7F).withOpacity(0.1),
                    border: Border.all(
                      color: _myFriendCode == 'Завантаження...' 
                          ? Colors.grey 
                          : const Color(0xFF58FF7F)
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy,
                        color: _myFriendCode == 'Завантаження...' 
                            ? Colors.grey 
                            : const Color(0xFF58FF7F),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Копіювати',
                        style: TextStyle(
                          color: _myFriendCode == 'Завантаження...' 
                              ? Colors.grey 
                              : const Color(0xFF58FF7F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Поділіться цим кодом з людьми, яких хочете додати до друзів',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }
}