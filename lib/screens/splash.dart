import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotibuddy/screens/home_page.dart';
import 'package:spotibuddy/screens/login_app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State {
  @override
  void initState() {
    super.initState();

    _mockCheckForSession().then((status) {
      if (status.isNotEmpty) {
        _navigateToHome(status);
      } else {
        _navigateToLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Future<String> _mockCheckForSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('sp_dc') ?? "";

    return token;
  }

  void _navigateToHome(String spDc) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) => MyHomePage(
          spDc: spDc,
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) => const LoginApp(),
      ),
    );
  }
}
