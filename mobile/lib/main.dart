import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/pasw_screen.dart';
import 'models/storage_user.dart';
import 'utils/init_settings_func.dart';
import 'models/storage_service.dart';
import 'models/storage_pasw.dart';
import 'models/storage_chat_key.dart';
import 'models/interface/user.dart';
import 'services/authentication.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initSecureStorage();
  initSettingsTheme();
  ChatKeysDB.initDatabase();

  final UserModel? user = await getUserStorage();
  final String? jwt = await getJWTStorage();
  final int? pasw = await getPaswStorage();

  if (user == null || jwt == null) {
    runApp(const LoginStart());
  } else {
    if (await getInfoToJwt(user.id, jwt)) {
      if (pasw == 0 || pasw == null) {
        runApp(const MainStart());
      } else {
        runApp(const PaswStart());
      }
    } else {
      runApp(const LoginStart());
    }
  }
}

class LoginStart extends StatelessWidget {
  const LoginStart({super.key});

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

class PaswStart extends StatelessWidget {
  const PaswStart({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voxta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PawsScreen(),
    );
  }
}

class MainStart extends StatelessWidget {
  const MainStart({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voxta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
