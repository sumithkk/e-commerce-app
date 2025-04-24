import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashion_app/features/main/screens/main_screen.dart';

class OtpMobileInputScreen extends StatefulWidget {
  const OtpMobileInputScreen({super.key});

  @override
  State<OtpMobileInputScreen> createState() => _OtpMobileInputScreenState();
}

class _OtpMobileInputScreenState extends State<OtpMobileInputScreen> {
  final mobileController = TextEditingController();
  final otpController = TextEditingController();

  bool isOtpSent = false;
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final response = await http.post(
      Uri.parse('http://57.128.166.138:2000/api/v1/admin/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": "${mobileController.text}@gravityer.com",
      }), // temporary trick
    );

    final data = jsonDecode(response.body);
    setState(() => isLoading = false);

    print('🔐 [Sent OTP] Status: $data');

    if (response.statusCode == 200) {
      setState(() => isOtpSent = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent to your number')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')),
      );
    }
  }

  Future<void> verifyOtp() async {
    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => isLoading = true);
    final response = await http.post(
      Uri.parse('http://57.128.166.138:2000/api/v1/admin/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": "${mobileController.text}@gravityer.com",
        "otp": otpController.text,
        "platform": "web",
      }),
    );

    final data = jsonDecode(response.body);
    setState(() => isLoading = false);

    if (response.statusCode == 200 && data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', data['token']);
      await prefs.setBool('isLoggedIn', true);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'OTP verification failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Login with OTP',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: mobileController,
                enabled: !isOtpSent,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                  prefixText: '+91 ',
                ),
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.trim().length != 10) {
                    return 'Enter valid 10-digit mobile number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              if (isOtpSent) ...[
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : verifyOtp,
                    child:
                        isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Verify OTP & Login'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : sendOtp,
                    child:
                        isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Send OTP'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
