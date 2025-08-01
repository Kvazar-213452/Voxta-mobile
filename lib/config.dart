import 'package:flutter/material.dart';

class Config {
  static const String URL_SERVICES_CRYPTO = "http://192.168.68.101:4002";
  static const String URL_SERVICES_AUNTIFICATION = "http://192.168.68.101:3000";
  static const String URL_SERVICES_CHAT = "http://192.168.68.101:3001";
}

class AppColors {
  static const Color primaryColor = Color(0xFF58FF7F);
  static const Color textLight = Color(0xFFEEEEEE);
  static const Color textMuted = Color(0xFFAAAAAA);
  static const Color inputBg = Color(0x1AFFFFFF);
  static const Color panelBg = Color(0x14FFFFFF);
  static const Color glowColor = Color(0xC758FF7F);
  
  static const List<Color> backgroundGradient = [
    Color(0xFF1F1F1F),
    Color(0xFF2D2D32),
    Color(0xFF232338),
  ];
}
