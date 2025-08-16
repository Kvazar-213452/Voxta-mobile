import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  void _onPinChanged(String value, int index) {
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
      _verifyPin();
    }
  }

  void _updatePin() {
    _enteredPin = _controllers.map((controller) => controller.text).join('');
  }

  void _verifyPin() {
    // Simulate PIN verification (replace with your logic)
    const correctPin = '123456'; // Example PIN
    
    if (_enteredPin == correctPin) {
      _onSuccess();
    } else {
      _onError();
    }
  }

  void _onSuccess() {
    HapticFeedback.lightImpact();
    // Navigate to next screen or perform success action
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN успішно введено!'),
        backgroundColor: Color(0xFF58FF7F),
        duration: Duration(seconds: 2),
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
      backgroundColor: const Color(0xFF1A1A1A),
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
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
            color: const Color(0xFF58FF7F).withOpacity(0.2),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: const Color(0xFF58FF7F),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.lock_outline,
            color: Color(0xFF58FF7F),
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Введіть PIN-код',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Введіть ваш 6-значний PIN-код для продовження',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
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
        color: const Color(0x1AFFFFFF),
        border: Border.all(
          color: _isError 
              ? Colors.red
              : _controllers[index].text.isNotEmpty 
                  ? const Color(0xFF58FF7F)
                  : Colors.white.withOpacity(0.2),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFEEEEEE),
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
          const SnackBar(
            content: Text('Функція відновлення PIN-коду'),
            backgroundColor: Color(0xFF2D2D32),
          ),
        );
      },
      child: Text(
        'Забули PIN-код?',
        style: TextStyle(
          fontSize: 16,
          color: const Color(0xFF58FF7F),
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}