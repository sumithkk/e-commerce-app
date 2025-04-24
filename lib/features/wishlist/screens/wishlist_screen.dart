import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> wishlistItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to view your wishlist.")),
      );
      return;
    }

    debugPrint("👤 [Wishlist] Loaded userId: $userId");

    final url = Uri.parse(
      "http://57.128.166.138:2000/api/v1/wishlist/customer/$userId",
    );
    final response = await http.get(url);

    debugPrint("📦 [Wishlist] Fetching from: $url");
    debugPrint("📬 [Wishlist] Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint("📄 [Wishlist] Body: ${response.body}");
      setState(() {
        wishlistItems = data['content'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load wishlist.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Wishlist")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : wishlistItems.isEmpty
              ? const Center(child: Text("Your wishlist is empty."))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: wishlistItems.length,
                itemBuilder: (context, index) {
                  final item = wishlistItems[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['image']['imageURI'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['brand'],
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "₹${item['formattedSalePrice']}",
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item['discount'] > 0)
                                  Text(
                                    "₹${item['formattedPrice']}",
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  children: List<Widget>.from(
                                    item['productOptions'].map((opt) {
                                      return Chip(
                                        label: Text(
                                          "${opt['name']}: ${opt['value']}",
                                        ),
                                        backgroundColor: Colors.grey[200],
                                        labelStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              // Add remove from wishlist logic here
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
