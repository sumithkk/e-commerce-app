import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:fashion_app/services/custom_dio.dart';
import 'package:fashion_app/features/auth/screens/email_login_screen.dart';
import 'package:fashion_app/features/product/screens/product_detail.dart';
import 'package:http/http.dart' as http;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Dio dio = CustomDio.instance;
  List<dynamic> cartItems = [];
  String subtotal = '';
  String shipping = '';
  String discount = '';
  String total = '';
  bool isLoading = true;
  bool isApplyingCoupon = false;
  final TextEditingController couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> logoutAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> fetchCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final cartId = prefs.getString('cartId');

    debugPrint("\u{1F4EC} [Cart] Status: $token");
    debugPrint("\u{1F4C4} [Cart] Body: $cartId");

    final url = 'http://57.128.166.138:2000/api/v1/cart/$cartId';

    debugPrint("\u{1F4C4} [Cart url ====================] Body: $url");

    try {
      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint("\u{1F4EC} [Cart] Status: ${response.statusCode}");
      debugPrint("\u{1F4C4} [Cart] Body: ${jsonEncode(response.data)}");

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          cartItems = data['lineItems'] ?? [];
          subtotal = formatPrice(data['cartTotal']['subTotal']);
          shipping = formatPrice(data['cartTotal']['shippingCharges']);
          discount = formatPrice(data['cartTotal']['couponDiscount']);
          total = formatPrice(data['cartTotal']['total']);
          isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logoutAndRedirect();
      }
      setState(() => isLoading = false);
    }
  }

  String formatPrice(dynamic value) {
    final parsed = double.tryParse(value.toString()) ?? 0;
    return parsed == parsed.roundToDouble()
        ? parsed.toInt().toString()
        : parsed.toStringAsFixed(2);
  }

  Future<void> removeFromCart(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('cartId');
    final token = prefs.getString('accessToken');

    if (token == null || cartId == null) return;

    final url = 'http://57.128.166.138:2000/api/v1/cart/$cartId/remove/$itemId';
    try {
      await dio.delete(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      fetchCart();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logoutAndRedirect();
      }
    }
  }

  Future<void> moveToWishlist(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken');

    if (userId == null || token == null) return;

    final url =
        'http://57.128.166.138:2000/api/v1/wishlist/customer/$userId/item/$itemId';
    try {
      await dio.post(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      removeFromCart(itemId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logoutAndRedirect();
      }
    }
  }

  Future<void> applyCoupon() async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('cartId');
    final email = prefs.getString('email');
    final token = prefs.getString('accessToken');

    if (cartId == null ||
        email == null ||
        token == null ||
        couponController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing fields')));
      return;
    }

    setState(() => isApplyingCoupon = true);

    final url = 'http://57.128.166.138:2000/api/v1/cart/apply-coupon';

    try {
      final response = await dio.post(
        url,
        data: {
          "cartId": cartId,
          "couponName": couponController.text.trim(),
          "mode": "web",
          "email": email,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon applied successfully!')),
        );
        fetchCart();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Failed to apply coupon'),
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logoutAndRedirect();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to apply coupon')));
    } finally {
      setState(() => isApplyingCoupon = false);
    }
  }

  Future<void> addToCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('cartId');
    final token = prefs.getString('accessToken');
    if (cartId == null) return;

    final response = await http.post(
      Uri.parse("http://57.128.166.138:2000/api/v1/cart/$cartId/add"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"id": int.parse(productId), "quantity": 1}),
    );
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      fetchCart(); // Refresh the UI
    }
  }

  Future<void> decrementCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('cartId');
    final token = prefs.getString('accessToken');
    if (cartId == null) return;

    final response = await http.post(
      Uri.parse("http://57.128.166.138:2000/api/v1/cart/$cartId/remove"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"id": int.parse(productId), "quantity": 1}),
    );

    if (response.statusCode == 200) {
      fetchCart(); // Refresh the UI
    }
  }

  Widget _buildPriceRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Cart"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: fetchCart, // 🌀 Pull to refresh
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Expanded(
                      child:
                          cartItems.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Lottie.asset(
                                      'assets/empty_wishlist.json',
                                      width: 250,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Your cart is empty",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.separated(
                                itemCount: cartItems.length,
                                physics: const AlwaysScrollableScrollPhysics(),
                                separatorBuilder:
                                    (_, __) => Divider(
                                      height: 0,
                                      color: Colors.grey.shade200,
                                    ),
                                itemBuilder: (context, index) {
                                  final item = cartItems[index];
                                  final isOutOfStock =
                                      item['isStockStatus'] == false;
                                  final discount = item['discount'] ?? 0;

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ProductDetailPage(
                                                productSlug: item['slug'],
                                              ),
                                        ),
                                      );
                                    },
                                    child: Slidable(
                                      key: ValueKey(item['id']),
                                      endActionPane: ActionPane(
                                        motion: const DrawerMotion(),
                                        children: [
                                          SlidableAction(
                                            onPressed:
                                                (_) => moveToWishlist(
                                                  item['item']?['id'] ??
                                                      item['id'],
                                                ),
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            icon: Icons.favorite_border,
                                            label: 'Wishlist',
                                          ),
                                          SlidableAction(
                                            onPressed:
                                                (_) =>
                                                    removeFromCart(item['id']),
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
                                          children: [
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Image.network(
                                                    item['image']['imageURI'],
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                if (isOutOfStock)
                                                  Positioned.fill(
                                                    child: Center(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.7),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          "OUT OF STOCK",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${item['brand'] ?? ''}: ${item['name']}",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "₹${formatPrice(item['formattedSalePrice'])}",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.teal,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      if (item['formattedPrice'] !=
                                                          item['formattedSalePrice'])
                                                        Text(
                                                          "₹${formatPrice(item['formattedPrice'])}",
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  if (discount > 0)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 4.0,
                                                          ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          "$discount% OFF",
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 10,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.remove,
                                                      size: 16,
                                                    ),
                                                    onPressed:
                                                        () => decrementCart(
                                                          item['id'],
                                                        ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 28,
                                                        ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                        ),
                                                    child: Text(
                                                      '${item['quantity']}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add,
                                                      size: 16,
                                                    ),
                                                    onPressed:
                                                        () => addToCart(
                                                          item['id'],
                                                        ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 28,
                                                        ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                    _buildCartSummary(),
                  ],
                ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: couponController,
                  decoration: InputDecoration(
                    hintText: 'Enter Coupon Code',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isApplyingCoupon ? null : applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.teal.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child:
                      isApplyingCoupon
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.teal,
                            ),
                          )
                          : const Text(
                            'Apply',
                            style: TextStyle(color: Colors.teal),
                          ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPriceRow("Subtotal", "₹$subtotal"),
          _buildPriceRow("Shipping", "₹$shipping"),
          _buildPriceRow("Discount", "- ₹$discount"),
          const Divider(height: 24, color: Colors.black),
          _buildPriceRow("Grand Total", "₹$total", bold: true),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              side: BorderSide(color: Colors.teal.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              "Proceed to Checkout",
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
