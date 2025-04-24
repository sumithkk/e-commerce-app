import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartService {
  // 🛒 Get Cart
  static Future<http.Response> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final cartId = prefs.getString('cartId');

    final url = Uri.parse('http://57.128.166.138:2000/en/api/v1/cart/$cartId');

    print('🛒 [GET CART] URL: $url');
    print('🛡️ [GET CART] Token: $token');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('🛒 [GET CART] Status: ${response.statusCode}');
    print('📦 [GET CART] Body: ${response.body}');
    return response;
  }

  // 🗑️ Remove from cart
  static Future<http.Response> removeCartItem(
    String cartId,
    int lineItemId,
  ) async {
    final url = Uri.parse(
      'http://57.128.166.138:2000/api/v1/cart/$cartId/remove/$lineItemId',
    );
    print('🗑️ [REMOVE ITEM] URL: $url');

    final response = await http.delete(url);
    print('🗑️ [REMOVE ITEM] Status: ${response.statusCode}');
    print('🗑️ [REMOVE ITEM] Body: ${response.body}');
    return response;
  }

  // 🎁 Apply Coupon
  static Future<http.Response> applyCoupon({
    required String cartId,
    required String couponName,
    required String email,
  }) async {
    final url = Uri.parse(
      "http://57.128.166.138:2000/api/v1/cart/apply-coupon",
    );

    final body = jsonEncode({
      "cartId": cartId,
      "couponName": couponName,
      "mode": "web",
      "email": email,
    });

    print('🎁 [APPLY COUPON] URL: $url');
    print('🎁 [APPLY COUPON] Body: $body');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    print('🎁 [APPLY COUPON] Status: ${response.statusCode}');
    print('🎁 [APPLY COUPON] Body: ${response.body}');
    return response;
  }

  // 🔁 Update cart quantity
  static Future<http.Response> updateCartItemQuantity({
    required String cartId,
    required int itemId,
    required int quantity,
  }) async {
    final url = Uri.parse('http://57.128.166.138:2000/api/v1/cart/$cartId/add');
    final body = jsonEncode({"id": itemId, "quantity": quantity});

    print('🔁 [UPDATE QTY] URL: $url');
    print('🔁 [UPDATE QTY] Body: $body');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    print('🔁 [UPDATE QTY] Status: ${response.statusCode}');
    print('🔁 [UPDATE QTY] Body: ${response.body}');
    return response;
  }
}
