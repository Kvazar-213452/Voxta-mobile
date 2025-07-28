import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  final String responseText;

  const MainScreen({super.key, required this.responseText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Головний екран')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          responseText,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
