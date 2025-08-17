import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'header.dart';
import 'footer.dart';
import 'utils.dart';
import '../../../../../utils/getImageBase64.dart';

class ProfileScreenWidget extends StatefulWidget {
  const ProfileScreenWidget({super.key});

  @override
  State<ProfileScreenWidget> createState() => _ProfileScreenWidgetState();
}

class _ProfileScreenWidgetState extends State<ProfileScreenWidget> 
  with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Дані профілю
  String _profileImageUrl = '';
  File? _selectedImage;
  String _userId = '';
  String _userTime = '';
  
  bool _isLoading = false;
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfileData();
  }

  void _setupAnimations() {
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
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isDataLoading = true;
      });

      // Використовуємо функцію з retry механізмом
      final userData = await getSelfWithRetry(maxRetries: 2);

      if (mounted) {
        setState(() {
          _nameController.text = userData['name']?.toString() ?? '';
          _descriptionController.text = userData['desc']?.toString() ?? '';
          _profileImageUrl = userData['avatar']?.toString() ?? '';
          _userId = 'ID: ${userData['id']?.toString() ?? 'Невідомо'}';
          _userTime = userData['time']?.toString() ?? 'Не вказано';
          _isDataLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDataLoading = false;
        });
        
        String errorMessage = 'Невідома помилка';
        
        if (e.toString().contains('secure_storage') || 
            e.toString().contains('CryptUnprotectData')) {
          errorMessage = 'Помилка системи безпеки. Перезапустіть додаток';
        } else if (e.toString().contains('з\'єднання')) {
          errorMessage = 'Немає з\'єднання з сервером';
        } else if (e.toString().contains('Час очікування')) {
          errorMessage = 'Сервер не відповідає. Спробуйте пізніше';
        } else {
          errorMessage = 'Помилка завантаження: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Повторити',
              textColor: Colors.white,
              onPressed: () => _loadProfileData(),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  void _closeProfile() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? avatarData = getImageBase64(_selectedImage);

      Map<String, dynamic> profileData = {
        'name': _nameController.text.trim(),
        'avatar': avatarData,
        'desc': _descriptionController.text.trim(),
      };

      saveProfile(profileData);

      setState(() {
        _isLoading = false;
      });

      _closeProfile();
    } catch (e) {
      print("Error saving profile: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1a1a1f),
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
                  child: _isDataLoading 
                    ? _buildLoadingScreen()
                    : Column(
                        children: [
                          ProfileHeaderWidget(onBackPressed: _closeProfile),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  const SizedBox(height: 30),
                                  _buildProfileImage(),
                                  const SizedBox(height: 30),
                                  _buildEditableFields(),
                                  const SizedBox(height: 20),
                                  _buildReadOnlyFields(),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                          ),
                          ProfileFooterWidget(
                            onSave: _saveProfile,
                            isLoading: _isLoading,
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

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58ff7f)),
          ),
          SizedBox(height: 20),
          Text(
            'Завантаження профілю...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: const Color(0xFF58ff7f),
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(57),
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : _profileImageUrl.isNotEmpty
                          ? Image.network(
                              _profileImageUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.white.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.white.withOpacity(0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58ff7f)),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 120,
                              height: 120,
                              color: Colors.white.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF58ff7f),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF1a1a1f),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Натисніть, щоб змінити фото',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableFields() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ім\'я користувача',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEEEEEE),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(
                  color: Color(0xFFEEEEEE),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Введіть ваше ім\'я...',
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
                      color: Color(0xFF58ff7f),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: Icon(
                    Icons.edit,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Це ім\'я буде відображатися в чатах',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Опис профілю',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEEEEEE),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 300,
                style: const TextStyle(
                  color: Color(0xFFEEEEEE),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Розкажіть про себе...',
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
                      color: Color(0xFF58ff7f),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: Icon(
                    Icons.description_outlined,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                  counterStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Коротко опишіть себе (максимум 300 символів)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyFields() {
    return Column(
      children: [
        _buildReadOnlyField(
          title: 'Унікальний ідентифікатор',
          value: _userId,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 15),
        _buildReadOnlyField(
          title: 'Дата реєстрації',
          value: _userTime,
          icon: Icons.schedule_outlined,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Не вказано' : value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                Icon(
                  Icons.lock_outline,
                  color: Colors.white.withOpacity(0.4),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// close