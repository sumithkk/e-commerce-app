import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:fashion_app/features/account/screens/edit_profile_screen.dart';
import 'package:fashion_app/features/account/screens/manage_address_screen.dart';
import 'package:fashion_app/features/auth/screens/email_login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final Dio dio = Dio()..interceptors.add(ChuckerDioInterceptor());
  Map<String, dynamic>? customer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomerDetails();
  }

  Future<void> fetchCustomerDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.get('userId')?.toString();
    final token = prefs.getString('accessToken');

    if (customerId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to view account')),
      );
      return;
    }

    final url = 'http://16.171.147.184:2000/api/v1/customer/$customerId';
    debugPrint("\u{1F464} [Account] Fetching from: $url");

    try {
      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint("\u{1F4EC} [Account] Status: ${response.statusCode}");
      debugPrint("\u{1F4C4} [Account] Body: ${jsonEncode(response.data)}");

      if (response.statusCode == 200) {
        setState(() {
          customer = response.data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("\u{274C} [Account] Error: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch account details')),
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) return;

    final url = 'http://16.171.147.184:2000/api/v1/auth/logout';

    try {
      final response = await dio.post(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        await prefs.clear();
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Logout failed')),
        );
      }
    } catch (e) {
      debugPrint("❌ [Logout] Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logout failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => ChuckerFlutter.showChuckerScreen(),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : customer == null
              ? const Center(child: Text("No customer data found."))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${customer!['firstName']} ${customer!['lastName']}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.teal,
                                    ),
                                    onPressed: () {
                                      // Navigate to edit profile page
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                customer!['email'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                customer!['phoneNumber'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.teal),
                            const SizedBox(height: 4),
                            const Text(
                              "Total Spent",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${customer!['totalSpent']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.teal,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Orders",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${customer!['orderCount']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ListTile(
                      leading: const Icon(Icons.edit, color: Colors.teal),
                      title: const Text("Edit Profile"),
                      onTap: () {
                        // Navigate to edit profile page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: Colors.teal,
                      ),
                      title: Text('Manage Addresses'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageAddressScreen(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.teal,
                      ),
                      title: const Text("My Orders"),
                      onTap: () {
                        // Navigate to orders page
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Logout'),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('Confirm Logout'),
                                content: const Text(
                                  'Are you sure you want to logout?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                        );

                        if (confirm == true) {
                          logout();
                        }
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
