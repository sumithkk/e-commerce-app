import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashion_app/features/main/screens/main_screen.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpMobileInputScreen extends StatefulWidget {
  const OtpMobileInputScreen({super.key});

  @override
  State<OtpMobileInputScreen> createState() => _OtpMobileInputScreenState();
}

class _OtpMobileInputScreenState extends State<OtpMobileInputScreen> {
  final TextEditingController contactController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isOtpSent = false;
  bool isLoading = false;
  bool isResendEnabled = false;
  Timer? _resendTimer;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    SmsAutoFill().listenForCode();
  }

  @override
  void dispose() {
    contactController.dispose();
    otpController.dispose();
    _resendTimer?.cancel();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  bool _isEmail(String input) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+\$').hasMatch(input);
  }

  void startResendTimer() {
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      isResendEnabled = false;
    });

    final input = contactController.text.trim();
    final isEmail = _isEmail(input);
    final body = isEmail ? {"phone": input} : {"email": input};

    print("\u{1F4E6} [CATEGORY API] Status: $body");

    final response = await http.post(
      Uri.parse('http://16.171.147.184:2000/api/v1/admin/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    setState(() => isLoading = false);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() => isOtpSent = true);
      startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'OTP sent successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')),
      );
    }
  }

  Future<void> verifyOtp() async {
    final input = contactController.text.trim();
    final isEmail = _isEmail(input);

    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => isLoading = true);
    final response = await http.post(
      Uri.parse('http://16.171.147.184:2000/api/v1/admin/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        isEmail ? 'email' : 'phone': input,
        "otp": otpController.text.trim(),
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
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('OTP Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Lottie.asset('assets/otp_animation.json', width: 180),
              const SizedBox(height: 16),
              Text(
                isOtpSent ? 'Verify OTP' : 'Login with OTP',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: contactController,
                enabled: !isOtpSent,
                decoration: const InputDecoration(
                  hintText: 'Email or Mobile Number',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter email or mobile number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              if (isOtpSent) ...[
                PinFieldAutoFill(
                  controller: otpController,
                  codeLength: 6,
                  decoration: UnderlineDecoration(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                    colorBuilder: FixedColorBuilder(Colors.teal),
                  ),
                  onCodeChanged: (code) {
                    if (code != null && code.length == 6) {
                      verifyOtp();
                    }
                  },
                ),
                const SizedBox(height: 16),
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
                if (!isResendEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Resend OTP in $_resendSeconds sec',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  TextButton(
                    onPressed: sendOtp,
                    child: const Text('Resend OTP'),
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
