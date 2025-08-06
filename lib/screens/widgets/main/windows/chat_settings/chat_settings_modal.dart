import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'utils.dart';
import 'chat_settings_header.dart';
import 'chat_settings_footer.dart';
import 'user_removal_dialog.dart';

class ChatSettingsModal extends StatefulWidget {
  final String currentName;
  final String currentDescription;
  final String typeChat;
  final String owner;
  final String time;
  final Widget? chatAvatar;
  final List<dynamic> users;
  final Function(String name, String description) onSave;

  const ChatSettingsModal({
    super.key,
    required this.currentName,
    required this.currentDescription,
    required this.typeChat,
    required this.owner,
    required this.time,
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
  bool _isLoadingUsers = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic> _usersData = {};

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.currentName);
    _descriptionController = TextEditingController(text: widget.currentDescription);
    

    getInfoUsers(
      users: widget.users,
      type: widget.typeChat,
      onSuccess: (Map<String, dynamic> usersData) {
        setState(() {
          _usersData = usersData;
          _isLoadingUsers = false;
        });
      },
      onError: (String error) {
        setState(() {
          _isLoadingUsers = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка завантаження: $error'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      },
    );
    
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

  void _removeUser(String userId) async {
    print('Видалити користувача з ID: $userId');
    final userData = _usersData[userId];
    final userName = userData?['name'] ?? 'Невідомий користувач';
    
    final result = await UserRemovalDialog.show(
      context: context,
      userId: userId,
      userName: userName,
    );
    
    if (result == true) {
      setState(() {
        _usersData.remove(userId);
      });
    }
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
                      ChatSettingsHeader(),
                      Flexible(
                        child: SingleChildScrollView(
                          child: _buildBody(),
                        ),
                      ),
                      ChatSettingsFooter(
                        isFormValid: _isFormValid,
                        onCancel: _closeModal,
                        onSave: _saveSettings,
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
          const SizedBox(height: 16),
          Text(
            'Дата створення: ${widget.time}',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Тип чату: ${widget.typeChat}',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildOwnerSection(),
          const SizedBox(height: 24),
          _buildUsersSection(),
        ],
      ),
    );
  }

  Widget _buildOwnerSection() {
    final ownerData = _usersData[widget.owner];
    
    if (_isLoadingUsers) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF58FF7F).withOpacity(0.3),
            width: 1,
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.star,
              color: const Color(0xFF58FF7F),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(  // Add Expanded to prevent overflow
              child: Text(
                ownerData?['name'] ?? 'Невідомий власник',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEEEEEE),
                ),
                maxLines: 1,  // Add maxLines
                overflow: TextOverflow.ellipsis,  // Add ellipsis for long names
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Власник чату',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF58FF7F).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Аватар власника
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF58FF7F).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: ownerData != null && ownerData['avatar'] != null && ownerData['avatar'].isNotEmpty
                      ? Image.network(
                          ownerData['avatar'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF58FF7F).withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: const Color(0xFF58FF7F).withOpacity(0.7),
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFF58FF7F).withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: const Color(0xFF58FF7F).withOpacity(0.7),
                            size: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: const Color(0xFF58FF7F),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ownerData?['name'] ?? 'Невідомий власник',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEEEEEE),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Учасники чату (${_usersData.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: _isLoadingUsers
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58FF7F)),
                  ),
                )
              : _usersData.isEmpty
                  ? Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Немає учасників для відображення',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _usersData.length,
                      itemBuilder: (context, index) {
                        final entry = _usersData.entries.elementAt(index);
                        final userId = entry.key;
                        final userData = entry.value;
                        
                        return _buildUserItem(
                          userId: userId,
                          name: userData['name'] ?? 'Невідомо',
                          avatar: userData['avatar'],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserItem({
    required String userId,
    required String name,
    String? avatar,
  }) {
    final isOwner = userId == widget.owner;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwner 
              ? const Color(0xFF58FF7F).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Аватар користувача
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOwner 
                    ? const Color(0xFF58FF7F).withOpacity(0.5)
                    : const Color(0xFF58FF7F).withOpacity(0.3),
                width: isOwner ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isOwner ? 18 : 19),
              child: avatar != null && avatar.isNotEmpty
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF58FF7F).withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: const Color(0xFF58FF7F).withOpacity(0.7),
                            size: 20,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF58FF7F).withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: const Color(0xFF58FF7F).withOpacity(0.7),
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isOwner) ...[
                      Icon(
                        Icons.star,
                        color: const Color(0xFF58FF7F),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isOwner ? FontWeight.w700 : FontWeight.w600,
                          color: isOwner 
                              ? const Color(0xFF58FF7F)
                              : const Color(0xFFEEEEEE),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isOwner)
            IconButton(
              onPressed: () => _removeUser(userId),
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Color(0xFFFF5555),
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFF5555).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF58FF7F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF58FF7F).withOpacity(0.3),
                ),
              ),
              child: Text(
                'Власник',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF58FF7F),
                ),
              ),
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
}

