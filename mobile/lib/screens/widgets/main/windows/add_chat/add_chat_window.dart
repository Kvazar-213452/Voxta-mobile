import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'header.dart';
import 'footer.dart';
import 'temporary_chat_modal.dart';
import '../../../../../services/chat/socket_service.dart';
import '../../../../../utils/getBase64.dart';
import '../../../../../app_colors.dart';

class AddChatScreen extends StatefulWidget {
  static final GlobalKey<_AddChatScreenState> addChatScreenKey =
      GlobalKey<_AddChatScreenState>();
  const AddChatScreen({Key? key}) : super(key: key);

  @override
  State<AddChatScreen> createState() => _AddChatScreenState();
}

class _AddChatScreenState extends State<AddChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _chatNameController = TextEditingController();
  final TextEditingController _chatDescriptionController =
      TextEditingController();

  File? _selectedImage;
  String _selectedPrivacy = 'online';
  bool _isFormValid = false;

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

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _chatNameController.addListener(_validateForm);
    _chatDescriptionController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chatNameController.dispose();
    _chatDescriptionController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _chatNameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _selectPrivacy(String privacy) {
    setState(() {
      _selectedPrivacy = privacy;
    });
  }

  void closeScreen() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _showTemporaryModal() {
    final avatarBase64 = getImageBase64(_selectedImage);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TemporaryChatModal(
          chatName: _chatNameController.text,
          chatDescription: _chatDescriptionController.text,
          privacy: _selectedPrivacy,
          avatarBase64: avatarBase64 ?? '',
          onCreateTemporary: (
            chatName,
            privacy,
            avatarBase64,
            chatDescription,
            expirationHours,
            password,
          ) {
            createTemporaryChat(
              chatName,
              privacy,
              avatarBase64,
              chatDescription,
              expirationHours,
              password,
            );
            closeScreen();
          },
        );
      },
    );
  }

  void _createChat() async {
    if (_isFormValid) {
      print('Creating chat: ${_chatNameController.text}');
      print('Description: ${_chatDescriptionController.text}');
      print('Privacy: $_selectedPrivacy');
      print('Has avatar: ${_selectedImage != null}');

      if (_selectedPrivacy == "temporary") {
        _showTemporaryModal();
      } else {
        final avatarBase64 = getImageBase64(_selectedImage);

        createChat(
          _chatNameController.text,
          _selectedPrivacy,
          avatarBase64 ?? '',
          _chatDescriptionController.text,
        );

        closeScreen();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: Transform.translate(
            offset: Offset(
              MediaQuery.of(context).size.width * _slideAnimation.value,
              0,
            ),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.gradientStart,
                      AppColors.gradientMiddle,
                      AppColors.gradientEnd,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      ChatHeader(onBack: closeScreen),
                      Expanded(child: _buildBody()),
                      ChatFooter(
                        onJoinChat: null,
                        onCreate: _createChat,
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
          _buildAvatarSection(),
          const SizedBox(height: 30),
          _buildChatNameSection(),
          const SizedBox(height: 30),
          _buildDescriptionSection(),
          const SizedBox(height: 30),
          _buildPrivacySection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Аватар чату',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.transparentWhite,
              border: Border.all(
                color:
                    _selectedImage != null
                        ? AppColors.brandGreen
                        : AppColors.white54,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (_selectedImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.file(
                      _selectedImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Аватар обрано',
                    style: TextStyle(
                      color: AppColors.brandGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.transparentWhite,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: AppColors.white54, width: 2),
                    ),
                    child: Icon(
                      Icons.add_a_photo,
                      color: AppColors.white70,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Оберіть зображення для аватару',
                    style: TextStyle(color: AppColors.white70, fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Підтримуються формати: JPG, PNG, GIF (макс. 5MB)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildChatNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Назва чату',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chatNameController,
          style: TextStyle(color: AppColors.lightGray, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Введіть назву чату...',
            hintStyle: TextStyle(color: AppColors.white54),
            filled: true,
            fillColor: AppColors.transparentWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.white54),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.white54),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.brandGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Оберіть зрозумілу назву для вашого чату',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Опис чату',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chatDescriptionController,
          maxLines: 4,
          style: TextStyle(color: AppColors.lightGray, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Опишіть тему або мету чату...',
            hintStyle: TextStyle(color: AppColors.white54),
            filled: true,
            fillColor: AppColors.transparentWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.white54),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.white54),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.brandGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Короткий опис допоможе іншим зрозуміти тему чату',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Приватність',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            _buildPrivacyOption(
              'online',
              '🌐',
              'Публічний',
              'Всі можуть приєднатися до чату',
            ),
            const SizedBox(height: 12),
            _buildPrivacyOption(
              'temporary',
              '⏱️',
              'Тимчасовий',
              'Чат з обмеженим часом існування',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacyOption(
    String value,
    String icon,
    String name,
    String description,
  ) {
    final isSelected = _selectedPrivacy == value;

    return GestureDetector(
      onTap: () => _selectPrivacy(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.brandGreen.withOpacity(0.1)
                  : AppColors.transparentWhite,
          border: Border.all(
            color: isSelected ? AppColors.brandGreen : AppColors.white54,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.brandGreen.withOpacity(0.2)
                        : AppColors.transparentWhite,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected
                              ? AppColors.brandGreen
                              : AppColors.lightGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: AppColors.white70),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.brandGreen, size: 24),
          ],
        ),
      ),
    );
  }
}