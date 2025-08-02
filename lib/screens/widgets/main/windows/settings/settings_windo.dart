import 'package:flutter/material.dart';
import 'modal.dart';
import 'header.dart';
import 'footer.dart';
import '../../../../../models/storage_settings.dart';
import '../../../../../models/interface/settings.dart';

class SettingsScreenWidget extends StatefulWidget {
  const SettingsScreenWidget({super.key});

  @override
  State<SettingsScreenWidget> createState() => _SettingsScreenWidgetState();
}

class _SettingsScreenWidgetState extends State<SettingsScreenWidget> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Стан налаштувань
  bool _darkMode = true;
  bool _browserNotifications = false;
  bool _doNotDisturb = false;
  bool _readReceipts = true;
  bool _onlineStatus = true;
  String _selectedLanguage = 'uk';
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsDB.getSettings();
      if (settings != null) {
        setState(() {
          _darkMode = settings.darkMode;
          _browserNotifications = settings.browserNotifications;
          _doNotDisturb = settings.doNotDisturb;
          _readReceipts = settings.readReceipts;
          _onlineStatus = settings.onlineStatus;
          _selectedLanguage = settings.language;
          _isLoading = false;
        });
      } else {
        // Якщо налаштувань немає, використовуємо дефолтні значення
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Обробка помилки завантаження
      print('Помилка завантаження налаштувань: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettingsToDb() async {
    try {
      final settings = Settings(
        darkMode: _darkMode,
        browserNotifications: _browserNotifications,
        doNotDisturb: _doNotDisturb,
        language: _selectedLanguage,
        readReceipts: _readReceipts,
        onlineStatus: _onlineStatus,
      );
      
      await SettingsDB.saveSettings(settings);
    } catch (e) {
      print('Помилка збереження налаштувань: $e');
      // Можна показати повідомлення про помилку користувачу
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeSettings() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _saveSettings() async {
    // Показуємо індикатор завантаження
    _showLoadingDialog();
    
    try {
      await _saveSettingsToDb();
      // Закриваємо діалог завантаження
      Navigator.of(context).pop();
      // Показуємо модал успіху
      _showSuccessModal();
    } catch (e) {
      // Закриваємо діалог завантаження
      Navigator.of(context).pop();
      // Показуємо повідомлення про помилку
      _showErrorDialog();
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58ff7f)),
        ),
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d2d32),
        title: const Text(
          'Помилка',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Не вдалося зберегти налаштування. Спробуйте ще раз.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF58ff7f)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SuccessModalWidget(),
    ).then((_) {
      _closeSettings();
    });
  }

  void _resetSettings() {
    setState(() {
      _darkMode = true;
      _browserNotifications = false;
      _doNotDisturb = false;
      _readReceipts = true;
      _onlineStatus = true;
      _selectedLanguage = 'uk';
    });
  }

  void _logout() {
    Navigator.of(context).pop();
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
              child: SafeArea(
                child: _isLoading 
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58ff7f)),
                      ),
                    )
                  : Column(
                      children: [
                        SettingsHeaderWidget(onBackPressed: _closeSettings),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildAppearanceSection(),
                                _buildNotificationsSection(),
                                _buildChatSection(),
                                _buildPrivacySection(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        SettingsFooterWidget(
                          onLogout: _logout,
                          onReset: _resetSettings,
                          onSave: _saveSettings,
                        ),
                      ],
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSection(
      title: '🎨 Зовнішній вигляд',
      children: [
        _buildToggleItem(
          title: 'Темна тема',
          subtitle: 'Використовувати темну тему оформлення',
          value: _darkMode,
          onChanged: (value) => setState(() => _darkMode = value),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSection(
      title: '🔔 Сповіщення',
      children: [
        _buildToggleItem(
          title: 'Браузерні сповіщення',
          subtitle: 'Показувати сповіщення в браузері',
          value: _browserNotifications,
          onChanged: (value) => setState(() => _browserNotifications = value),
        ),
        _buildToggleItem(
          title: 'Режим "Не турбувати"',
          subtitle: 'Вимкнути всі сповіщення',
          value: _doNotDisturb,
          onChanged: (value) => setState(() => _doNotDisturb = value),
        ),
      ],
    );
  }

  Widget _buildChatSection() {
    return _buildSection(
      title: '💬 Чат',
      children: [
        _buildDropdownItem(
          title: 'Мова інтерфейсу',
          subtitle: 'Вибрати мову додатка',
          value: _selectedLanguage,
          items: const [
            DropdownMenuItem(value: 'uk', child: Text('Українська')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) => setState(() => _selectedLanguage = value!),
        )
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSection(
      title: '🔒 Приватність',
      children: [
        _buildToggleItem(
          title: 'Читання повідомлень',
          subtitle: 'Показувати коли повідомлення прочитане',
          value: _readReceipts,
          onChanged: (value) => setState(() => _readReceipts = value),
        ),
        _buildToggleItem(
          title: 'Статус онлайн',
          subtitle: 'Показувати коли ви онлайн',
          value: _onlineStatus,
          onChanged: (value) => setState(() => _onlineStatus = value),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          _buildToggleSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDropdownItem({
    required String title,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: DropdownButton<String>(
                value: value,
                items: items,
                onChanged: onChanged,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                dropdownColor: const Color(0xFF2d2d32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? const Color(0xFF58ff7f) : Colors.white.withOpacity(0.2),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
