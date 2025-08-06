import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatSettingsModal extends StatefulWidget {
  final String currentName;
  final String currentDescription;
  final Widget? chatAvatar;
  final List<dynamic> users;
  final Function(String name, String description) onSave;

  const ChatSettingsModal({
    super.key,
    required this.currentName,
    required this.currentDescription,
    this.chatAvatar,
    this.users = const [],
    required this.onSave,
  });

  @override
  State<ChatSettingsModal> createState() => _ChatSettingsModalState();
}

class _ChatSettingsModalState extends State<ChatSettingsModal> with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isFormValid = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.currentName);
    _descriptionController = TextEditingController(text: widget.currentDescription);
    
    // Виводимо список користувачів в консоль
    print('Користувачі чату: ${widget.users}');
    
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
    
    _nameController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
    _validateForm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _nameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        print('Вибрано зображення з галереї: ${image.path}');
      }
    } catch (e) {
      print('Помилка вибору зображення: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка вибору зображення: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _saveSettings() {
    if (_isFormValid) {
      widget.onSave(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
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
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
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
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Відображаємо аватарку чату або стандартну іконку
          widget.chatAvatar != null
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF58FF7F).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: widget.chatAvatar!,
                  ),
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF58FF7F).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF58FF7F),
                    size: 20,
                  ),
                ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              '⚙️ Налаштування чату',
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
            'Налаштуйте параметри чату:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(height: 20),
          _buildAvatarSection(),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _nameController,
            label: 'Назва чату',
            hint: 'Введіть назву чату...',
            maxLength: 50,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _descriptionController,
            label: 'Опис чату',
            hint: 'Введіть опис чату...',
            maxLines: 3,
            maxLength: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Аватар чату',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Відображаємо поточний аватар або заглушку
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF58FF7F).withOpacity(0.3),
                  width: 2,
                ),
                color: widget.chatAvatar == null && _selectedImage == null
                    ? const Color(0xFF58FF7F).withOpacity(0.1)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      )
                    : widget.chatAvatar != null
                        ? widget.chatAvatar!
                        : Icon(
                            Icons.group,
                            color: const Color(0xFF58FF7F).withOpacity(0.7),
                            size: 28,
                          ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58FF7F).withOpacity(0.2),
                      foregroundColor: const Color(0xFF58FF7F),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: const Color(0xFF58FF7F).withOpacity(0.3),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(
                      _selectedImage != null ? 'Змінити аватар' : 'Додати аватар',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG або GIF до 5MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
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
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(
            color: Color(0xFFEEEEEE),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
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
            counterStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
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
              onPressed: _isFormValid ? _saveSettings : null,
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
                'Зберегти',
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