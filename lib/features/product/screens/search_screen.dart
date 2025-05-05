import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fashion_app/widgets/product_card.dart';
import 'package:fashion_app/features/product/screens/product_detail.dart';

class SearchResultsPage extends StatefulWidget {
  final String keyword;
  const SearchResultsPage({super.key, required this.keyword});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<dynamic> searchResults = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSearchResults();
  }

  Future<void> fetchSearchResults() async {
    final url = Uri.parse(
      'http://57.128.166.138:2000/api/v1/line/item/search?term=${widget.keyword}',
    );
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'isGuest': 'true',
      },
    );
    debugPrint("\u{1F4EC} [Account] Status: $url");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['content']?[0]?['lineItems'] ?? [];
      setState(() {
        searchResults = items;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load search results")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Results for '${widget.keyword}'"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : searchResults.isEmpty
              ? const Center(child: Text("No results found"))
              : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.59,
                ),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final item = searchResults[index];
                  return ProductCard(
                    itemId: item['id'].toString(),
                    imageUrl: item['image']['imageURI'],
                    brand: item['brand'] ?? '',
                    name: item['name'],
                    price: item['formattedSalePrice'],
                    originalPrice: item['formattedPrice'],
                    isWishlisted: false,
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
                      // TODO: Add to cart integration if needed
                    },
                    onWishlistToggle: () {
                      // TODO: Add to wishlist integration if needed
                    },
                  );
                },
              ),
    );
  }
}
