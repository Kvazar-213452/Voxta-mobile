import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'utils.dart';
import 'chat_settings_header.dart';
import 'chat_settings_footer.dart';
import 'widgets/chat_basic_widgets.dart';
import 'widgets/chat_users_widgets.dart';
import 'widgets/chat_invite_widgets.dart';
import 'user_removal_dialog.dart';
import '../../../../../services/chat/socket_service.dart';
import 'utils.dart';

class ChatSettingsModal extends StatefulWidget {
  final String currentName;
  final String currentDescription;
  final String typeChat;
  final String owner;
  final String time;
  final String chatId;
  final Widget? chatAvatar;
  final List<dynamic> users;
  final String? currentInviteCode;
  final Function(String name, String description, String? avatar) onSave;

  const ChatSettingsModal({
    super.key,
    required this.currentName,
    required this.currentDescription,
    required this.typeChat,
    required this.owner,
    required this.time,
    this.chatAvatar,
    this.users = const [],
    this.currentInviteCode,
    required this.onSave,
    required this.chatId,
  });

  @override
  State<ChatSettingsModal> createState() => _ChatSettingsModalState();
}

class _ChatSettingsModalState extends State<ChatSettingsModal> with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isFormValid = false;
  bool _isLoadingUsers = true;
  bool _isGeneratingInviteCode = false;
  String? _currentInviteCode;
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
    _currentInviteCode = widget.currentInviteCode;
    
    _initializeUsers();
    _initializeAnimations();
    _setupFormValidation();
  }

  void _initializeUsers() {
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
  }

  void _initializeAnimations() {
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
  }

  void _setupFormValidation() {
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
    final userData = _usersData[userId];
    final userName = userData?['name'] ?? 'Невідомий користувач';
    
    final result = await UserRemovalDialog.show(
      context: context,
      userId: userId,
      userName: userName,
    );

    if (result == true) {
      setState(() {
        delUserInChat(widget.chatId, widget.typeChat, userId);
      });

      _closeModal();
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

  Future<void> _generateInviteCode() async {
    setState(() {
      _isGeneratingInviteCode = true;
    });

    try {
      String newInviteCode = await generateRandomCode(widget.chatId);

      setState(() {
        _currentInviteCode = newInviteCode;
      });
    } catch (e) {
      print('Помилка генерації коду: $e');
    } finally {
      setState(() {
        _isGeneratingInviteCode = false;
      });
    }
  }

  Future<void> _deleteInviteCode() async {
    try {
      socket!.emit('del_key_chat', {
        'id': widget.chatId
      });

      setState(() {
        _currentInviteCode = null;
      });
    } catch (e) {
      print('Помилка видалення коду: $e');
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_selectedImage == null) return null;
    
    try {
      final bytes = await _selectedImage!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Помилка конвертації зображення в base64: $e');
      return null;
    }
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _saveSettings() async {
    if (_isFormValid) {
      String? avatarBase64;
      
      if (_selectedImage != null) {
        avatarBase64 = await _convertImageToBase64();
      }
      
      widget.onSave(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        avatarBase64,
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
                      const ChatSettingsHeader(),
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
          ChatAvatarSection(
            chatAvatar: widget.chatAvatar,
            selectedImage: _selectedImage,
            onPickImage: _pickImage,
          ),
          const SizedBox(height: 20),
          ChatInputField(
            controller: _nameController,
            label: 'Назва чату',
            hint: 'Введіть назву чату...',
            maxLength: 50,
          ),
          const SizedBox(height: 16),
          ChatInputField(
            controller: _descriptionController,
            label: 'Опис чату',
            hint: 'Введіть опис чату...',
            maxLines: 3,
            maxLength: 200,
          ),
          const SizedBox(height: 16),
          ChatInfoSection(
            time: widget.time,
            typeChat: widget.typeChat,
          ),
          const SizedBox(height: 16),
          ChatInviteCodesSection(
            currentInviteCode: _currentInviteCode,
            isGenerating: _isGeneratingInviteCode,
            onGenerateCode: _generateInviteCode,
            onDeleteCode: _deleteInviteCode,
          ),
          const SizedBox(height: 16),
          ChatOwnerSection(
            owner: widget.owner,
            usersData: _usersData,
            isLoadingUsers: _isLoadingUsers,
          ),
          const SizedBox(height: 24),
          ChatUsersSection(
            usersData: _usersData,
            isLoadingUsers: _isLoadingUsers,
            owner: widget.owner,
            onRemoveUser: _removeUser,
          ),
        ],
      ),
    );
  }
}

// generateRandomCode