import 'package:flutter/material.dart';
import '../../../app_colors.dart';

class LoginPanel extends StatelessWidget {
  final Widget child;

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
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.transparentWhite,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowBlack30,
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