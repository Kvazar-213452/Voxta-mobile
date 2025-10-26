import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
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

  void _onSuccess() {
    HapticFeedback.lightImpact();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainStart(),
      ),
    );
  }

  void _onError() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isError = true;
    });
    
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
    _focusNodes[0].requestFocus();
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
                    const SizedBox(height: 40),
                    _buildForgotPin(),
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
            color: AppColors.brandGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: AppColors.brandGreen,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.lock_outline,
            color: AppColors.brandGreen,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Введіть PIN-код',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Введіть ваш 6-значний PIN-код для продовження',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.whiteText.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPinInput() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * (_shakeController.status == AnimationStatus.reverse ? -1 : 1), 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) => _buildPinField(index)),
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
          if (_isError) {
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

  Widget _buildForgotPin() {
    return GestureDetector(
      onTap: () {
        // Handle forgot PIN
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Функція відновлення PIN-коду'),
            backgroundColor: AppColors.gradientMiddle,
          ),
        );
      },
      child: Text(
        'Забули PIN-код?',
        style: TextStyle(
          fontSize: 16,
          color: AppColors.brandGreen,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}