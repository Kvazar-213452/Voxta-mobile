import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/storage_pasw.dart';
import '../main.dart';
import '../../app_colors.dart';

class PawsScreen extends StatefulWidget {
  const PawsScreen({Key? key}) : super(key: key);

  @override
  State<PawsScreen> createState() => _PawsScreenState();
}

class _PawsScreenState extends State<PawsScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;
  
  String _enteredPin = '';
  bool _isError = false;
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;
  bool _isLocked = false;
  
  // Тривалість блокування в секундах
  static const List<int> _lockoutDurations = [30, 60, 300, 900]; // 30с, 1хв, 5хв, 15хв

  @override
  void initState() {
    super.initState();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
    _loadLockoutState();
    
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLocked) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  Future<void> _loadLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    final failedAttempts = prefs.getInt('failed_attempts') ?? 0;
    final lockoutEndTimeMs = prefs.getInt('lockout_end_time');
    
    setState(() {
      _failedAttempts = failedAttempts;
      if (lockoutEndTimeMs != null) {
        _lockoutEndTime = DateTime.fromMillisecondsSinceEpoch(lockoutEndTimeMs);
        if (_lockoutEndTime!.isAfter(DateTime.now())) {
          _isLocked = true;
          _startLockoutTimer();
        } else {
          _isLocked = false;
          _lockoutEndTime = null;
        }
      }
    });
  }

  Future<void> _saveLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('failed_attempts', _failedAttempts);
    if (_lockoutEndTime != null) {
      await prefs.setInt('lockout_end_time', _lockoutEndTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('lockout_end_time');
    }
  }

  void _startLockoutTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!)) {
        setState(() {});
        _startLockoutTimer();
      } else {
        setState(() {
          _isLocked = false;
          _lockoutEndTime = null;
        });
        _saveLockoutState();
        _focusNodes[0].requestFocus();
      }
    });
  }

  String _getRemainingLockoutTime() {
    if (_lockoutEndTime == null) return '';
    
    final remaining = _lockoutEndTime!.difference(DateTime.now());
    if (remaining.isNegative) return '';
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes хв ${seconds} с';
    } else {
      return '$seconds с';
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _onPinChanged(String value, int index) async {
    if (_isLocked) return;
    
    setState(() {
      _isError = false;
    });

    if (value.isNotEmpty) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Unfocus when last digit is entered
        _focusNodes[index].unfocus();
      }
    }
    
    _updatePin();
    
    // Check if PIN is complete
    if (_enteredPin.length == 6) {
      await _verifyPin();
    }
  }

  void _updatePin() {
    _enteredPin = _controllers.map((controller) => controller.text).join('');
  }

  Future<void> _verifyPin() async {
    final correctPin = await getPaswStorage();
    
    if (_enteredPin == correctPin?.toString()) {
      _onSuccess();
    } else {
      _onError();
    }
  }

  Future<void> _onSuccess() async {
    HapticFeedback.lightImpact();
    
    // Скидаємо лічильник невдалих спроб
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('failed_attempts');
    await prefs.remove('lockout_end_time');

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainStart(),
      ),
    );
  }

  Future<void> _onError() async {
    HapticFeedback.heavyImpact();
    
    setState(() {
      _failedAttempts++;
      _isError = true;
    });
    
    await _saveLockoutState();
    
    // Перевіряємо, чи потрібно блокувати
    if (_failedAttempts >= 4) {
      final lockoutIndex = (_failedAttempts - 4).clamp(0, _lockoutDurations.length - 1);
      final lockoutDuration = _lockoutDurations[lockoutIndex];
      
      setState(() {
        _lockoutEndTime = DateTime.now().add(Duration(seconds: lockoutDuration));
        _isLocked = true;
      });
      
      await _saveLockoutState();
      _startLockoutTimer();
      
      // Знімаємо фокус з полів
      for (var focusNode in _focusNodes) {
        focusNode.unfocus();
      }
    }
    
    _shakeController.forward().then((_) {
      _shakeController.reverse().then((_) {
        // Clear all fields after animation
        Future.delayed(const Duration(milliseconds: 500), () {
          _clearPin();
        });
      });
    });
  }

  void _clearPin() {
    setState(() {
      _isError = false;
      for (var controller in _controllers) {
        controller.clear();
      }
      _enteredPin = '';
    });
    if (!_isLocked) {
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    _buildHeader(),
                    const SizedBox(height: 60),
                    _buildPinInput(),
                    const SizedBox(height: 20),
                    _buildAttemptsInfo(),
                    const SizedBox(height: 40),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: (_isLocked ? AppColors.errorRed : AppColors.brandGreen).withOpacity(0.2),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: _isLocked ? AppColors.errorRed : AppColors.brandGreen,
              width: 2,
            ),
          ),
          child: Icon(
            _isLocked ? Icons.lock : Icons.lock_outline,
            color: _isLocked ? AppColors.errorRed : AppColors.brandGreen,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLocked ? 'Заблоковано' : 'Введіть PIN-код',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLocked 
              ? 'Забагато невдалих спроб. Спробуйте знову через:'
              : 'Введіть ваш 6-значний PIN-код для продовження',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.whiteText.withOpacity(0.7),
          ),
        ),
        if (_isLocked) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.errorRed,
                width: 1,
              ),
            ),
            child: Text(
              _getRemainingLockoutTime(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.errorRed,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttemptsInfo() {
    if (_failedAttempts == 0 || _isLocked) return const SizedBox.shrink();
    
    final remainingAttempts = 4 - _failedAttempts;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.errorRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Залишилось спроб: $remainingAttempts',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.errorRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinInput() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * (_shakeController.status == AnimationStatus.reverse ? -1 : 1), 0),
          child: Opacity(
            opacity: _isLocked ? 0.4 : 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildPinField(index)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinField(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.transparentWhite,
        border: Border.all(
          color: _isError 
              ? AppColors.errorRed
              : _controllers[index].text.isNotEmpty 
                  ? AppColors.brandGreen
                  : AppColors.whiteText.withOpacity(0.2),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        enabled: !_isLocked,
        style: TextStyle(
          color: AppColors.lightGray,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        keyboardType: TextInputType.number,
        maxLength: 1,
        obscureText: false,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onPinChanged(value, index),
        onTap: () {
          // Clear field on tap if error state
          if (_isError && !_isLocked) {
            _clearPin();
          }
        },
        onEditingComplete: () {
          if (index < 5 && _controllers[index].text.isNotEmpty) {
            _focusNodes[index + 1].requestFocus();
          }
        },
      ),
    );
  }
}