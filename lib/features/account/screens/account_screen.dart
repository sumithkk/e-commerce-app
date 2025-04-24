import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashion_app/features/auth/screens/email_login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? firstName, lastName, email, phone;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
      email = prefs.getString('email');
      phone = prefs.getString('phoneNumber');
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('My Account'), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // 👤 Default Avatar
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),

          const SizedBox(height: 20),

          // 👤 User Info
          Text(
            fullName.isNotEmpty ? fullName : "Guest User",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(email ?? '-', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(phone ?? '-', style: const TextStyle(color: Colors.grey)),

          const Spacer(),

          // 🔓 Logout Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
