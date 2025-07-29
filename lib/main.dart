import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'module/storage_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await readFromSecureStorage('example_key');

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
      home: const LoginScreen(),
    );
  }
}
