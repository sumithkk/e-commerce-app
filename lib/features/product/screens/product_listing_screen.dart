import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashion_app/widgets/product_card.dart';
import 'package:fashion_app/features/product/screens/product_detail.dart';

class ProductListPage extends StatefulWidget {
  final String categorySlug;
  final String categoryName;

  const ProductListPage({
    super.key,
    required this.categorySlug,
    required this.categoryName,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  int currentPage = 1;
  bool isLastPage = false;
  String selectedSort = "newestFirst";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !isLastPage) {
        currentPage++;
        fetchProducts();
      }
    });
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
      "http://57.128.166.138:2000/api/v1/category/term/${widget.categorySlug}?page=$currentPage&size=10&sort=$selectedSort",
    );
    final response = await http.get(url, headers: {"isGuest": "true"});

    debugPrint("📦 [PL API] Status: ${response.statusCode}");
    debugPrint("🛍️ [PL API] Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['content']?[0]?['lineItems'] ?? [];
      final isLast = data['last'] ?? true;

      setState(() {
        products.addAll(items);
        isLoading = false;
        isLastPage = isLast;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load products")));
    }
  }

  void onSortChanged(String value) {
    setState(() {
      selectedSort = value;
      products.clear();
      currentPage = 1;
      isLastPage = false;
    });
    fetchProducts();
  }

  Future<void> addToCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('cartId');

    if (cartId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cart ID not found.")));
      return;
    }

    final url = Uri.parse("http://57.128.166.138:2000/api/v1/cart/$cartId/add");
    final body = jsonEncode({"id": int.parse(productId), "quantity": 1});

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    debugPrint("🛒 [Add to Cart] Status: ${response.statusCode}");
    debugPrint("🛒 [Add to Cart] Body: ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Item added to cart!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add item to cart.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          PopupMenuButton<String>(
            onSelected: onSortChanged,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'newestFirst',
                    child: Text('Newest'),
                  ),
                  const PopupMenuItem(
                    value: 'priceLowToHigh',
                    child: Text('Price - Low to High'),
                  ),
                  const PopupMenuItem(
                    value: 'priceHighToLow',
                    child: Text('Price - High to Low'),
                  ),
                  const PopupMenuItem(
                    value: 'nameAsc',
                    child: Text('Name A-Z'),
                  ),
                  const PopupMenuItem(
                    value: 'nameDesc',
                    child: Text('Name Z-A'),
                  ),
                ],
            child: Row(
              children: const [
                Icon(Icons.sort),
                SizedBox(width: 4),
                Text("Sort"),
                SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
      body:
          isLoading && products.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
              ? const Center(child: Text("No products found."))
              : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= products.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final item = products[index];
                  final price = item['salePrice'] ?? item['price'] ?? '0';
                  final imageUrl =
                      item['image'] is String
                          ? item['image']
                          : item['image']?['imageURI'];

                  return ProductCard(
                    imageUrl: imageUrl,
                    name: item['name'],
                    price: price.toString(),
                    originalPrice: item['price']?.toString(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  ProductDetailPage(productSlug: item['slug']),
                        ),
                      );
                    },
                    onAddToCart: () {
                      addToCart(item['id'].toString());
                    },
                    onWishlistToggle: () {
                      // TODO: Toggle wishlist
                    },
                    isWishlisted: false,
                  );
                },
              ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
