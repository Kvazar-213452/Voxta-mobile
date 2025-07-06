// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // <-- імпортуємо екран

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voxta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(), // <-- викликаємо новий екран
    );
  }
}
