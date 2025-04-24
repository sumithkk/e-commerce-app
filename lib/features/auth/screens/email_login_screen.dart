import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'dart:convert';
import 'package:fashion_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashion_app/features/main/screens/main_screen.dart';
import 'package:fashion_app/features/auth/screens/otp_mobile_input_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final response = await AuthService.login(
        email: emailController.text,
        password: passwordController.text,
      );

      print('🔐 [LOGIN] Status: ${response.statusCode}');
      print('📦 [LOGIN] Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['token']);
        await prefs.setString('refreshToken', data['refreshToken']);
        await prefs.setInt('customerId', data['customerId']);
        await prefs.setString('cartId', data['cartId']);
        await prefs.setString('wishlistId', data['wishlistId']);
        await prefs.setString('email', data['email']);
        await prefs.setString('firstName', data['firstName']);
        await prefs.setString('lastName', data['lastName']);
        await prefs.setString('phoneNumber', data['phoneNumber']);
        await prefs.setBool('isLoggedIn', true);

        // Navigate to home screen and clear stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // Email Input
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Input with toggle
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),

                const SizedBox(height: 8),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: _submit,
                    child: const Text('Login'),
                  ),
                ),

                const SizedBox(height: 24),

                // Social login
                const Text(
                  'Or login with',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.facebook, color: Colors.blue),
                      iconSize: 32,
                      onPressed: () {
                        // TODO: Facebook login
                      },
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                      iconSize: 40,
                      onPressed: () {
                        // TODO: Google login
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Login with OTP
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OtpMobileInputScreen(),
                      ),
                    );
                  },
                  child: const Text('Login with OTP'),
                ),

                // Sign Up Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
