import 'package:flutter/material.dart';

class LoginBackground extends StatelessWidget {
  final Widget child;

  static const Color glowColor = Color(0xC758FF7F);

  const LoginBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: MediaQuery.of(context).size.width * 0.6,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}