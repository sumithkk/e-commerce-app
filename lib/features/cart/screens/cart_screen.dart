import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fashion_app/services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? cartData;
  bool isLoading = true;
  final couponController = TextEditingController();
  final Map<int, TextEditingController> qtyControllers = {};

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    final response = await CartService.getCart();
    if (response.statusCode == 200) {
      setState(() {
        cartData = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      print('❌ Failed to load cart: ${response.statusCode}');
      setState(() => isLoading = false);
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _updateQty(int id, int newQty) async {
    final cartId = cartData?['id'];
    if (newQty <= 0) return;

    final res = await CartService.updateCartItemQuantity(
      cartId: cartId,
      itemId: id,
      quantity: newQty,
    );

    if (res.statusCode == 200) {
      setState(() => qtyControllers[id]?.text = newQty.toString());
      await fetchCart();
      showSnack("Quantity updated");
    } else {
      showSnack("❌ Failed to update");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineItems = cartData?['lineItems'] ?? [];
    final totals = cartData?['cartTotal'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("My Cart")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : cartData == null
              ? const Center(child: Text("Failed to load cart"))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (lineItems.isNotEmpty)
                      Expanded(child: _buildCartList(lineItems)),
                    if (lineItems.isEmpty) _buildEmptyState(),
                    const SizedBox(height: 16),
                    if (lineItems.isNotEmpty) _buildCouponInput(),
                    if (lineItems.isNotEmpty) _buildCartSummary(totals),
                    if (lineItems.isNotEmpty) _buildCheckoutButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildCartList(List<dynamic> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id'];
        qtyControllers[id] ??= TextEditingController(
          text: item['quantity'].toString(),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                item['image'] != null
                    ? Image.network(
                      item['image']['imageURI'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                    : const Icon(Icons.image, size: 60),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Product',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              final currentQty =
                                  int.tryParse(
                                    qtyControllers[id]?.text ?? '1',
                                  ) ??
                                  1;
                              if (currentQty > 1) {
                                _updateQty(id, currentQty - 1);
                              }
                            },
                          ),
                          SizedBox(
                            width: 40,
                            child: TextFormField(
                              controller: qtyControllers[id],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true),
                              onFieldSubmitted: (val) {
                                final qty = int.tryParse(val);
                                if (qty != null && qty > 0) {
                                  _updateQty(id, qty);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              final currentQty =
                                  int.tryParse(
                                    qtyControllers[id]?.text ?? '1',
                                  ) ??
                                  1;
                              _updateQty(id, currentQty + 1);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final cartId = cartData?['id'];
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text("Remove Item"),
                                      content: const Text(
                                        "Are you sure you want to remove this item?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text("Remove"),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                final res = await CartService.removeCartItem(
                                  cartId,
                                  item['id'],
                                );
                                if (res.statusCode == 200) {
                                  showSnack("Item removed successfully");
                                  await fetchCart();
                                } else {
                                  showSnack("Failed to remove item");
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text("₹${item['salePrice'].toStringAsFixed(2)}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCouponInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Apply Coupon",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: couponController,
                decoration: const InputDecoration(
                  hintText: "Enter coupon code",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final code = couponController.text.trim();
                final cartId = cartData?['id'];
                final email = cartData?['email'] ?? 'svk@gravityer.com';
                if (code.isEmpty || cartId == null) {
                  showSnack("Enter a valid coupon and ensure cart is loaded.");
                  return;
                }
                final response = await CartService.applyCoupon(
                  cartId: cartId,
                  couponName: code,
                  email: email,
                );
                if (response.body.isNotEmpty) {
                  final result = jsonDecode(response.body);
                  if (response.statusCode == 200 && result['success'] == true) {
                    showSnack("🎁 Coupon Applied Successfully!");
                    await fetchCart();
                  } else {
                    showSnack(result['message'] ?? "❌ Failed to apply coupon");
                  }
                } else {
                  showSnack("❌ Failed to apply coupon. No response body.");
                }
              },
              child: const Text("Apply"),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCartSummary(Map<String, dynamic> totals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        _summaryRow("Subtotal", totals['formattedSubTotal']),
        _summaryRow("Shipping", totals['formattedShippingCharges']),
        _summaryRow("Tax", totals['formattedTax']),
        _summaryRow("Coupon Discount", totals['formattedCouponDiscount']),
        const Divider(),
        _summaryRow("Total", totals['formattedTotal'], isBold: true),
      ],
    );
  }

  Widget _summaryRow(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            "₹$value",
            style:
                isBold
                    ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.payment),
          label: const Text("Proceed to Checkout"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            showSnack("Proceeding to checkout (mock only)");
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          'https://cdn-icons-png.flaticon.com/512/2038/2038854.png',
          height: 180,
        ),
        const SizedBox(height: 24),
        const Text(
          "Your cart is empty",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
