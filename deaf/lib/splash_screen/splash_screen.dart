import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:drivers/assistants/assistant_methods.dart';
import 'package:drivers/global/global.dart';
import 'package:drivers/screens/login_screen.dart';
import 'package:drivers/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void startTimer() {
    Timer(Duration(seconds: 3), () async {
      if (firebaseAuth.currentUser != null) {
        await AssistantMethods.readCurrentOnlineUserInfo();
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (c) => const MainScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (c) => const LoginScreen()));
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Deaf Care",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
