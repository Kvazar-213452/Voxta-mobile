import 'package:flutter/material.dart';

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

  bool _darkMode = true;
  bool _browserNotifications = false;
  bool _doNotDisturb = false;
  bool _readReceipts = true;
  bool _onlineStatus = true;
  String _selectedLanguage = 'uk';

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

  void _saveSettings() {
    _showSuccessModal();
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
                child: Column(
                  children: [
                    _buildHeader(),
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
                    _buildFooter(),
                  ],
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
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _closeSettings,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 15),
          const Text(
            '⚙️ Налаштування',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterButton(
              text: 'Вихід',
              color: Colors.red.withOpacity(0.2),
              textColor: Colors.red.shade300,
              onTap: _logout,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFooterButton(
              text: 'Скинути',
              color: Colors.white.withOpacity(0.1),
              textColor: Colors.white,
              onTap: _resetSettings,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFooterButton(
              text: 'Зберегти',
              color: const Color(0xFF58ff7f),
              textColor: Colors.black,
              onTap: _saveSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// Success Modal Widget
class SuccessModalWidget extends StatefulWidget {
  const SuccessModalWidget({super.key});

  @override
  State<SuccessModalWidget> createState() => _SuccessModalWidgetState();
}

class _SuccessModalWidgetState extends State<SuccessModalWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.all(30),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a1f),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFF58ff7f),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 40,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Voxta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF58ff7f),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Налаштування збережено успішно!\nВсі зміни застосовано.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF58ff7f),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Готово',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}