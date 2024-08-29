import 'package:flutter/material.dart';
import 'package:drivers/screens/forgot_password_screen.dart';
import 'package:drivers/screens/login_screen.dart';
import 'package:drivers/screens/main_screen.dart';
import 'package:drivers/screens/register_screen.dart';
import 'package:drivers/splash_screen/splash_screen.dart';
import 'package:drivers/theme_provider/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'tab_pages/sound_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.system,
      home: SplashScreen(),
    );
  }
}



