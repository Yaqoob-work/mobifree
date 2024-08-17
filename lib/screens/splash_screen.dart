import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/main.dart';

void main() {
  runApp(SplashScreen());
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyHomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Center(
        // child: Image.asset('assets/images/logo.png'),
        child: Image.asset('assets/logo.png', width: screenwdt * 0.5),
      ),
    );
  }
}
