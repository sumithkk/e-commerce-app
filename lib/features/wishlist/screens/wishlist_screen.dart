import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Dio dio = Dio()..interceptors.add(ChuckerDioInterceptor());
  List<dynamic> wishlist = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('userId')?.toString();
    final token = prefs.getString('accessToken');

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to view wishlist')),
      );
      return;
    }

    final url = 'http://57.128.166.138:2000/api/v1/wishlist/customer/$userId';
    debugPrint("📤 [Wishlist] Fetching from: $url");

    try {
      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          wishlist = response.data['content'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ [Wishlist] Error: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to fetch wishlist')));
    }
  }

  Future<void> removeFromWishlist(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('userId')?.toString();
    final token = prefs.getString('accessToken');
    if (userId == null || token == null) return;

    final url =
        'http://57.128.166.138:2000/api/v1/wishlist/customer/$userId/remove/$itemId';
    try {
      await dio.delete(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      fetchWishlist();
    } catch (e) {
      debugPrint("❌ [Remove Wishlist] Error: $e");
    }
  }

  Future<void> moveToCart(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final cartId = prefs.getString('cartId');
    final userId = prefs.get('userId')?.toString();

    if (token == null || cartId == null) return;

    final removeUrl =
        'http://57.128.166.138:2000/api/v1/wishlist/customer/$userId/remove/$itemId';
    final addToCartUrl = 'http://57.128.166.138:2000/api/v1/cart/$cartId/add';

    try {
      await dio.post(
        addToCartUrl,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {'id': itemId, 'quantity': 1},
      );
      await dio.delete(
        removeUrl,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moved to cart successfully ✅'),
          backgroundColor: Colors.green,
        ),
      );
      fetchWishlist();
    } catch (e) {
      debugPrint("❌ [Move to Cart Error]: $e");
    }
  }

  void navigateToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Wishlist"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
              : wishlist.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/empty_wishlist.json', width: 250),
                    const SizedBox(height: 16),
                    const Text(
                      "Your wishlist is empty",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: navigateToHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text("Start Shopping"),
                    ),
                  ],
                ),
              )
              : ListView.separated(
                itemCount: wishlist.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final item = wishlist[index];
                  final discount = item['discount'] ?? 0;
                  final isOutOfStock = item['isStockStatus'] == false;
                  final options = item['productOptions'] ?? [];

                  return Slidable(
                    key: ValueKey(item['id']),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed:
                              (_) =>
                                  moveToCart(item['item']?['id'] ?? item['id']),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          icon: Icons.shopping_cart,
                          label: 'Cart',
                        ),
                        SlidableAction(
                          onPressed: (_) => removeFromWishlist(item['id']),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item['image']['imageURI'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (isOutOfStock)
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "OUT OF STOCK",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['brand'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "₹${item['formattedSalePrice']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (item['formattedPrice'] !=
                                        item['formattedSalePrice'])
                                      Text(
                                        "₹${item['formattedPrice']}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    if (discount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          "$discount% OFF",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (options.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children:
                                          options.map<Widget>((opt) {
                                            return Chip(
                                              label: Text(
                                                "${opt['name']}: ${opt['value']}",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                              backgroundColor: Colors.grey[100],
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                              ],
                            ),
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
