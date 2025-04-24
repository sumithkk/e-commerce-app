import 'package:flutter/material.dart';
import 'otp_screen.dart'; // Add this import

Route createCustomRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      const begin = Offset(0.0, 1.0); // Slide from bottom
      const end = Offset.zero;
      const curve = Curves.easeOut;

      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // App title/logo
              Text(
                'FASHION',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 48),

              const Text(
                'Login with Phone',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              const Text(
                'We’ll send you an OTP to verify your number.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Phone Input Field
              TextFormField(
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '+91 ',
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Send OTP Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Navigate to OTP screen
                    Navigator.of(
                      context,
                    ).push(createCustomRoute(const OtpScreen()));
                  },
                  child: const Text(
                    'Send OTP',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
