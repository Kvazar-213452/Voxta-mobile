import 'package:flutter/material.dart';
import '../../../../../app_colors.dart';
import 'utils.dart';

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
  String _selectedFrequency = '0';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final Map<String, String> _frequencies = {
    '0': 'Ніколи',
    '10': 'Кожні 10 повідомлень',
    '50': 'Кожні 50 повідомлень',
    '100': 'Кожні 100 повідомлень',
    '200': 'Кожні 200 повідомлень',
    '500': 'Кожні 500 повідомлень',
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
    getInterval(
      chatId: widget.chatId,
      onSuccess: (String interval) {
        if (!mounted) return;

        setState(() {
          _selectedFrequency = interval;
        });
      },
      onError: (String error) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка завантаження: $error'),
            backgroundColor: AppColors.destructiveRed,
            duration: const Duration(seconds: 3),
          ),
        );
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

  void _saveSettings() async {
    await setInterval(widget.chatId, _selectedFrequency);
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
                    children: [_buildHeader(), _buildBody(), _buildFooter()],
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
                  'Автоматичне оновлення',
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
                  items:
                      _frequencies.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(
                                entry.key.isEmpty
                                    ? Icons.block
                                    : Icons.schedule,
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