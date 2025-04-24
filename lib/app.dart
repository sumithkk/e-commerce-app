import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/screens/email_login_screen.dart';
import 'package:fashion_app/features/main/screens/main_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fashion App',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data == true) {
            return const MainScreen();
          } else {
            return const EmailLoginScreen();
          }
        },
      ),
    );
  }
}
