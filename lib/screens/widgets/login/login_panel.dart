import 'package:flutter/material.dart';

class LoginPanel extends StatelessWidget {
  final Widget child;

  static const Color inputBg = Color(0x1AFFFFFF);
  static const Color panelBg = Color(0x14FFFFFF);

  const LoginPanel({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 350,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: inputBg,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}