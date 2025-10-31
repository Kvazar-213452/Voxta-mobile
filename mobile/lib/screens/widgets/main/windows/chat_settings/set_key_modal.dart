import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app_colors.dart';
import '../../../../../models/storage_chat_key.dart';
import '../../../../../utils/crypto/crypto_msg.dart';

class SetKeyModal extends StatefulWidget {
  final String chatId;
  final String chatName;
  final VoidCallback onClose;

  const SetKeyModal({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.onClose,
  });

  @override
  State<SetKeyModal> createState() => _SetKeyModalState();
}

class _SetKeyModalState extends State<SetKeyModal>
    with TickerProviderStateMixin {
  final TextEditingController _keyController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _loadKey();

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

  Future<void> _loadKey() async {
    final key = await ChatKeysDB.getKey(widget.chatId);
    if (mounted) {
      setState(() {
        _keyController.text = key;
      });
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
      widget.onClose();
    });
  }

  void _generateKey() {
    setState(() {
      _keyController.text = generateKey();
    });
  }

  Future<void> _pasteKey() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _keyController.text = clipboardData.text!;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ключ вставлено'),
            backgroundColor: AppColors.brandGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Буфер обміну порожній'),
            backgroundColor: AppColors.destructiveRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _copyKey() {
    if (_keyController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _keyController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ключ скопійовано'),
          backgroundColor: AppColors.brandGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveKey() {
    if (_keyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Введіть ключ'),
          backgroundColor: AppColors.destructiveRed,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ChatKeysDB.addKey(widget.chatId, _keyController.text);
    _closeModal();
  }

  void _deleteKey() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.modalBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Видалити ключ?',
            style: TextStyle(color: AppColors.whiteText),
          ),
          content: Text(
            'Ви впевнені, що хочете видалити ключ доступу?',
            style: TextStyle(color: AppColors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Скасувати',
                style: TextStyle(color: AppColors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ChatKeysDB.deleteKey(widget.chatId);
                _closeModal();
              },
              child: Text(
                'Видалити',
                style: TextStyle(color: AppColors.destructiveRed),
              ),
            ),
          ],
        );
      },
    );
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
            child: Icon(Icons.key, color: AppColors.brandGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Встановити ключ',
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
                    'Згенеруйте ключ для шифрування чату',
                    style: TextStyle(fontSize: 13, color: AppColors.lightGray),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ключ доступу',
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
                  child: TextField(
                    controller: _keyController,
                    readOnly: true,
                    enableInteractiveSelection: false,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.lightGray,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Згенеруйте ключ',
                      hintStyle: TextStyle(
                        color: AppColors.whiteTransparent50,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    color:
                        _keyController.text.isEmpty
                            ? AppColors.white54.withOpacity(0.3)
                            : AppColors.white54,
                    size: 20,
                  ),
                  onPressed: _keyController.text.isEmpty ? null : _copyKey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generateKey,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandGreen,
                    side: BorderSide(
                      color: AppColors.brandGreenTransparent30,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.autorenew, size: 18),
                  label: Text(
                    'Згенерувати',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pasteKey,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandGreen,
                    side: BorderSide(
                      color: AppColors.brandGreenTransparent30,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.content_paste, size: 18),
                  label: Text(
                    'Вставити',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _keyController.text.isEmpty ? null : _deleteKey,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.destructiveRed,
                  side: BorderSide(
                    color:
                        _keyController.text.isEmpty
                            ? AppColors.whiteTransparent20
                            : AppColors.destructiveRed.withOpacity(0.5),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color:
                      _keyController.text.isEmpty
                          ? AppColors.white54.withOpacity(0.3)
                          : AppColors.destructiveRed,
                ),
              ),
            ],
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
              onPressed: _saveKey,
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
                  Icon(Icons.save, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Зберегти',
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