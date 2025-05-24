import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashion_app/widgets/product_card.dart';
import 'package:fashion_app/features/product/screens/product_detail.dart';
import 'package:dio/dio.dart';

final Dio dio = Dio();

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
      "http://16.171.147.184:2000/api/v1/category/term/${widget.categorySlug}?page=$currentPage&size=10&sort=$selectedSort",
    );
    final response = await http.get(url, headers: {"isGuest": "true"});

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

  Future<void> refreshProducts() async {
    setState(() {
      currentPage = 1;
      products.clear();
      isLastPage = false;
    });
    await fetchProducts();
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

  Future<void> addToWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to add to wishlist')),
      );
      return;
    }

    final url =
        'http://16.171.147.184:2000/api/v1/wishlist/customer/$userId/item/$productId';

    final response = await dio.post(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to wishlist')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to wishlist')),
      );
    }
  }

  Future<void> addToCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('cartId');
    final token = prefs.getString('accessToken');

    if (cartId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cart ID not found.")));
      return;
    }

    final url = Uri.parse("http://16.171.147.184:2000/api/v1/cart/$cartId/add");
    final body = jsonEncode({"id": int.parse(productId), "quantity": 1});

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            onSelected: onSortChanged,
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'newestFirst', child: Text('Newest')),
                  PopupMenuItem(
                    value: 'priceLowToHigh',
                    child: Text('Price - Low to High'),
                  ),
                  PopupMenuItem(
                    value: 'priceHighToLow',
                    child: Text('Price - High to Low'),
                  ),
                  PopupMenuItem(value: 'nameAsc', child: Text('Name A-Z')),
                  PopupMenuItem(value: 'nameDesc', child: Text('Name Z-A')),
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
      body: RefreshIndicator(
        onRefresh: refreshProducts,
        child: Container(
          color: Colors.white,
          child:
              isLoading && products.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                  ? const Center(child: Text("No products found."))
                  : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.59,
                        ),
                    itemCount: products.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= products.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final item = products[index];
                      return ProductCard(
                        imageUrl: item['image']['imageURI'],
                        brand: item['brand'] ?? '',
                        name: item['name'],
                        price: item['formattedSalePrice'],
                        originalPrice: item['formattedPrice'],
                        isWishlisted: false,
                        itemId:
                            item['id']
                                .toString(), // Pass the itemId for the RatingWidget
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
                        onAddToCart: () {
                          addToCart(item['id'].toString());
                        },
                        onWishlistToggle: () {
                          addToWishlist(item['id'].toString());
                        },
                      );
                    },
                  ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
