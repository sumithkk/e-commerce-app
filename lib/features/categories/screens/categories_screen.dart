import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:fashion_app/features/product/screens/product_listing_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

final List<String> fallbackImages = [
  'https://picsum.photos/200',
  'https://picsum.photos/201',
  'https://picsum.photos/202',
  'https://picsum.photos/203',
];

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final url = Uri.parse("http://57.128.166.138:2000/api/v1/category");
    final response = await http.get(url, headers: {"isGuest": "true"});

    print("\u{1F4E6} [CATEGORY API] Status: ${response.statusCode}");
    print("\u{1F5C2}\u{FE0F} [CATEGORY API] Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        categories = data ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load categories")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),
      body:
          isLoading
              ? _buildShimmerLoading()
              : RefreshIndicator(
                onRefresh: fetchCategories,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryItem(context, category);
                  },
                ),
              ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, dynamic category) {
    final String? imageUrl = category['image']?['imageURI'];

    // Create a list of random fallback images
    final List<String> fallbackImages = [
      'https://picsum.photos/300',
      'https://picsum.photos/201',
      'https://picsum.photos/202',
      'https://picsum.photos/203',
    ];

    // Pick a random fallback based on category ID
    final randomFallback =
        fallbackImages[(category['id'] ?? 0) % fallbackImages.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProductListPage(
                  categorySlug: category['slug'],
                  categoryName: category['name'],
                ),
          ),
        );
      },
      child: Hero(
        tag: category['slug'],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl != null && imageUrl.isNotEmpty
                    ? imageUrl
                    : randomFallback,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(randomFallback, fit: BoxFit.cover);
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: Text(
                    category['name'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
