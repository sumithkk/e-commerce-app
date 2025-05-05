import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/screens/email_login_screen.dart';
import 'features/main/screens/main_screen.dart';
import 'package:fashion_app/features/account/screens/add_edit_address_screen.dart'; // 👈 Add this import
import 'package:chucker_flutter/chucker_flutter.dart';

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
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(), // Apply Poppins font
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      navigatorObservers: [ChuckerFlutter.navigatorObserver],
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
      routes: {
        '/addAddress':
            (context) => const AddEditAddressScreen(), // 👈 Route for Add
        '/editAddress':
            (context) => const AddEditAddressScreen(), // 👈 Route for Edit
      },
    );
  }
}
