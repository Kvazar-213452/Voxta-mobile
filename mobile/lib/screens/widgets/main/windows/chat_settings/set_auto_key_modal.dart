import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app_colors.dart';
import '../../../../../models/storage_chat_key.dart';
import '../../../../../utils/crypto/crypto_msg.dart';

class SetAutoKeyModal extends StatefulWidget {
  final String chatId;
  final String chatName;
  final VoidCallback onClose;

  const SetAutoKeyModal({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.onClose,
  });

  @override
  State<SetAutoKeyModal> createState() => _SetAutoKeyModalState();
}

class _SetAutoKeyModalState extends State<SetAutoKeyModal>
    with TickerProviderStateMixin {
  String _currentKey = '';
  bool _showKey = false;
  int _syncedUsers = 0;
  String _selectedFrequency = '24'; // 24 години за замовчуванням

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final Map<String, String> _frequencies = {
    '12': '12 годин',
    '24': '1 день',
    '168': '7 днів',
  };

  @override
  void initState() {
    super.initState();

    _loadData();

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
  }

  Future<void> _loadData() async {
    final key = await ChatKeysDB.getKey(widget.chatId);
    // TODO: Завантажити кількість синхронізованих користувачів з API
    // TODO: Завантажити збережену частоту генерації
    if (mounted) {
      setState(() {
        _currentKey = key;
        _syncedUsers = 0; // Тимчасово
        _selectedFrequency = '24'; // Тимчасово
      });
    }
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

  Future<void> _synchronizeKey() async {
    // TODO: Реалізувати синхронізацію ключа з сервером
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Синхронізація...'),
        backgroundColor: AppColors.brandGreen,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Симуляція генерації нового ключа
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newKey = generateKey();
    await ChatKeysDB.addKey(widget.chatId, newKey);
    
    if (mounted) {
      setState(() {
        _currentKey = newKey;
        _showKey = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ключ синхронізовано успішно'),
          backgroundColor: AppColors.brandGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleShowKey() {
    setState(() {
      _showKey = !_showKey;
    });
  }

  void _copyKey() {
    if (_currentKey.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _currentKey));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ключ скопійовано'),
          backgroundColor: AppColors.brandGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveSettings() {
    // TODO: Зберегти налаштування частоти на сервері
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Налаштування збережено'),
        backgroundColor: AppColors.brandGreen,
        duration: const Duration(seconds: 2),
      ),
    );
    _closeModal();
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
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
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
            child: Icon(Icons.sync, color: AppColors.brandGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Автоматичний ключ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.chatName,
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Інформаційне повідомлення
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
                    'Ключ автоматично оновлюється та синхронізується',
                    style: TextStyle(fontSize: 13, color: AppColors.lightGray),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Кнопка синхронізації
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _synchronizeKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.blackText,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
              ),
              icon: Icon(Icons.sync, size: 20),
              label: Text(
                'Синхронізувати ключ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Поточний ключ
          Text(
            'Поточний ключ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.whiteTransparent50,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
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
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.vpn_key,
                    color: AppColors.brandGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _currentKey.isEmpty
                          ? 'Ключ не встановлено'
                          : (_showKey ? _currentKey : '••••••••••••••••'),
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            _currentKey.isEmpty
                                ? AppColors.whiteTransparent50
                                : AppColors.lightGray,
                        fontWeight: FontWeight.w600,
                        letterSpacing: _showKey ? 1 : 2,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showKey ? Icons.visibility_off : Icons.visibility,
                    color:
                        _currentKey.isEmpty
                            ? AppColors.white54.withOpacity(0.3)
                            : AppColors.white54,
                    size: 20,
                  ),
                  onPressed: _currentKey.isEmpty ? null : _toggleShowKey,
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    color:
                        _currentKey.isEmpty
                            ? AppColors.white54.withOpacity(0.3)
                            : AppColors.white54,
                    size: 20,
                  ),
                  onPressed: _currentKey.isEmpty ? null : _copyKey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Кількість синхронізованих користувачів
          Container(
            padding: const EdgeInsets.all(16),
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenTransparent20,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.people,
                    color: AppColors.brandGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Синхронізовано користувачів',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.lightGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenTransparent20,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.brandGreenTransparent30,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$_syncedUsers',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.brandGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Частота генерації
          Text(
            'Частота генерації ключа',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.whiteTransparent50,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.transparentWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.brandGreenTransparent30,
                width: 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                  value: _selectedFrequency,
                  isExpanded: true,
                  dropdownColor: AppColors.modalBackground,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.brandGreen,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.lightGray,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  items: _frequencies.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: AppColors.brandGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(entry.value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFrequency = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
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
            child: OutlinedButton(
              onPressed: _closeModal,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white70,
                side: BorderSide(color: AppColors.whiteTransparent20),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Скасувати',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveSettings,
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
                  Icon(Icons.check, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Застосувати',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}