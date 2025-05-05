import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart'; // 👈 Added Lottie import

class ManageAddressScreen extends StatefulWidget {
  const ManageAddressScreen({super.key});

  @override
  State<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends State<ManageAddressScreen> {
  final Dio dio = Dio()..interceptors.add(ChuckerDioInterceptor());
  List<dynamic> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('userId')?.toString();
    final token = prefs.getString('accessToken');

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to view addresses')),
      );
      return;
    }

    final url = 'http://57.128.166.138:2000/api/v1/address/customer/$userId';
    debugPrint("📦 [Address] Fetching from: $url");

    try {
      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint("📬 [Address] Status: ${response.statusCode}");
      debugPrint("📄 [Address] Body: ${jsonEncode(response.data)}");

      if (response.statusCode == 200) {
        setState(() {
          addresses = response.data['content'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ [Address] Error: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch addresses')),
      );
    }
  }

  Future<void> deleteAddress(int addressId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) return;

    final url = 'http://57.128.166.138:2000/api/v1/address/$addressId';
    debugPrint("🗑️ [Delete Address] URL: $url");

    try {
      final response = await dio.delete(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully')),
        );
        fetchAddresses();
      }
    } catch (e) {
      debugPrint("❌ [Delete Address] Error: $e");
    }
  }

  void navigateToAddAddress() {
    Navigator.pushNamed(context, '/addAddress').then((_) => fetchAddresses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Addresses"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: navigateToAddAddress, // 👈 Corrected navigation
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : addresses.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/empty_address.json', // 👈 Add the Lottie animation
                      width: 250,
                      repeat: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No addresses found!",
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: navigateToAddAddress,
                      child: const Text("Add Address"),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final item = addresses[index];
                  return Slidable(
                    key: ValueKey(item['id']),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            Navigator.pushNamed(
                              context,
                              '/editAddress',
                              arguments: item, // Pass this
                            ).then((_) => fetchAddresses());
                          },
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: 'Edit',
                        ),
                        SlidableAction(
                          onPressed: (context) {
                            showDialog(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: const Text('Delete Address'),
                                    content: const Text(
                                      'Are you sure you want to delete this address?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          deleteAddress(item['id']);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.teal,
                      ),
                      title: Text("${item['line1']}, ${item['city']}"),
                      subtitle: Text(item['country'] ?? ''),
                    ),
                  );
                },
              ),
    );
  }
}
