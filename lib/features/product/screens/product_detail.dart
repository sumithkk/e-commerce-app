import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:fashion_app/widgets/product_deck.dart';
import 'package:http/http.dart' as http;
import 'package:fashion_app/widgets/ratingWidget.dart'; // Import the RatingWidget

final Dio dio = Dio()..interceptors.add(ChuckerDioInterceptor());

class ProductDetailPage extends StatefulWidget {
  final String productSlug;

  const ProductDetailPage({super.key, required this.productSlug});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? product;
  bool isLoading = true;
  int currentImageIndex = 0;
  int quantity = 1;
  final PageController _pageController = PageController();
  List<dynamic> images = [];
  bool isDescriptionExpanded = false;
  double? rating;
  int totalElements = 0;
  final TextEditingController reviewController = TextEditingController();
  int selectedRating = 0;

  @override
  void initState() {
    super.initState();
    fetchProductDetail();
  }

  Future<void> fetchProductDetail() async {
    final url =
        'http://16.171.147.184:2000/api/v1/line/item/term/${widget.productSlug}';
    final response = await dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'isGuest': 'true',
        },
      ),
    );

    debugPrint("\u{1F4EC} [Account] Status: ${response.statusCode}");
    debugPrint("\u{1F4C4} [Account] Body: ${jsonEncode(response.data)}");

    if (response.statusCode == 200) {
      setState(() {
        product = response.data;
        images = product?['images'] ?? [];

        final productId =
            product?['id']?.toString() ??
            'default_id'; // Fallback to a default value if null
        fetchRating(productId); // Fetch rating after loading product details

        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load product details')),
      );
    }
  }

  Future<void> fetchRating(String itemId) async {
    final url =
        'http://16.171.147.184:2000/api/v1/ratings/line-item/$itemId?size=100&page=1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        rating = data['overallRating']['rating'];
        totalElements = data['totalElements'];
      });
    } else {
      debugPrint("Failed to load rating");
    }
  }

  Future<void> submitReview() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('userId');
    final token = prefs.getString('accessToken');
    final productId = product?['id']?.toString();

    if (customerId == null || productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to submit a review')),
      );
      return;
    }

    final url =
        'http://16.171.147.184:2000/api/v1/ratings/line-item/$productId';

    final body = jsonEncode({
      'rating': selectedRating,
      'review': reviewController.text,
      'customerId': customerId,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
      reviewController.clear();
      setState(() {
        // Re-fetch reviews or update UI accordingly
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to submit review')));
    }
  }

  Future<void> addToWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken');

    debugPrint("\u{1F4EC} [Account] Status: $userId");
    debugPrint("\u{1F4C4} [Account] Body: $token");

    if (userId == null || product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to add to wishlist')),
      );
      return;
    }

    final productId = product!['id'];
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

    debugPrint("\u{1F4EC} [Account] Status: ${response.statusCode}");
    debugPrint("\u{1F4C4} [Account] Body: ${jsonEncode(response.data)}");

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

  void changeImageBasedOnColor(String? imageUrl) {
    if (imageUrl == null) return;
    final index = images.indexWhere((img) => img['imageURI'] == imageUrl);
    if (index != -1) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => currentImageIndex = index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = product?['productOptions'] as List<dynamic>? ?? [];
    final breadcrumbs = product?['breadcrumbs'] as List<dynamic>? ?? [];
    final isStockStatus = product?['isStockStatus'] ?? false;
    final discount = product?['discount'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(product?['name'] ?? 'Product Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: addToWishlist,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => ChuckerFlutter.showChuckerScreen(),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : product == null
              ? const Center(child: Text('No product found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumbs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(breadcrumbs.length, (index) {
                          final crumb = breadcrumbs[index];
                          final isLast = index == breadcrumbs.length - 1;
                          return Text(
                            isLast ? crumb['label'] : "${crumb['label']} > ",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Image Carousel
                    Stack(
                      children: [
                        Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged:
                                    (index) => setState(
                                      () => currentImageIndex = index,
                                    ),
                                itemCount: images.length,
                                itemBuilder:
                                    (context, index) => Image.network(
                                      images[index]['imageURI'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        index,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                      setState(() => currentImageIndex = index);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color:
                                              currentImageIndex == index
                                                  ? Colors.teal
                                                  : Colors.grey,
                                        ),
                                      ),
                                      child: Image.network(
                                        images[index]['imageURI'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        if (discount != null)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "$discount% OFF",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        if (!isStockStatus)
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "OUT OF STOCK",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Product Info with Brand and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product!['brand'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        RatingWidget(
                          itemId:
                              product?['id']?.toString() ??
                              'default_id', // Fallback to 'default_id' if product['id'] is null
                          rating: rating ?? 0.0, // Provide rating
                          totalReviews: totalElements, // Provide totalReviews
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product!['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "₹${product!['formattedSalePrice']}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product!['formattedPrice'] !=
                            product!['formattedSalePrice'])
                          Text(
                            "₹${product!['formattedPrice']}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed:
                                    () => setState(
                                      () =>
                                          quantity > 1 ? quantity-- : quantity,
                                    ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () => setState(() => quantity++),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            final id = product?['id'];
                            if (id != null) {
                              addToCart(id.toString());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: const BorderSide(color: Colors.green),
                            ),
                          ),
                          label: const Text(
                            "Add to Cart",
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),
                    ...options.map((opt) {
                      final isColorOption = opt['values'].any(
                        (val) => val['colorImage'] != null,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          isColorOption
                              ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List<Widget>.from(
                                  (opt['values'] as List).map((val) {
                                    final img = val['colorImage']?['imageURI'];
                                    return GestureDetector(
                                      onTap: () => changeImageBasedOnColor(img),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Image.network(
                                          img,
                                          width: 40,
                                          height: 40,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              )
                              : DropdownButton<String>(
                                value:
                                    (opt['values'] as List).firstWhere(
                                      (v) => v['selected'] == true,
                                      orElse: () => opt['values'][0],
                                    )['name'],
                                items:
                                    (opt['values'] as List)
                                        .map<DropdownMenuItem<String>>((val) {
                                          return DropdownMenuItem(
                                            value: val['name'],
                                            child: Text(val['name']),
                                          );
                                        })
                                        .toList(),
                                onChanged: (val) {},
                              ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          () => setState(
                            () =>
                                isDescriptionExpanded = !isDescriptionExpanded,
                          ),
                      child: Text(
                        product!['description'] ?? '',
                        textAlign: TextAlign.justify,
                        maxLines: isDescriptionExpanded ? null : 4,
                        overflow:
                            isDescriptionExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      '⭐ Reviews (mock)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Great product!'),
                      subtitle: Text('Loved the quality and design.'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Good value'),
                      subtitle: Text('Worth the price I paid.'),
                    ),

                    const SizedBox(height: 32),

                    // Review Submission Form
                    const Text(
                      '📝 Submit Your Review',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Enter your review',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.star),
                          color:
                              selectedRating >= 1 ? Colors.yellow : Colors.grey,
                          onPressed: () => setState(() => selectedRating = 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.star),
                          color:
                              selectedRating >= 2 ? Colors.yellow : Colors.grey,
                          onPressed: () => setState(() => selectedRating = 2),
                        ),
                        IconButton(
                          icon: const Icon(Icons.star),
                          color:
                              selectedRating >= 3 ? Colors.yellow : Colors.grey,
                          onPressed: () => setState(() => selectedRating = 3),
                        ),
                        IconButton(
                          icon: const Icon(Icons.star),
                          color:
                              selectedRating >= 4 ? Colors.yellow : Colors.grey,
                          onPressed: () => setState(() => selectedRating = 4),
                        ),
                        IconButton(
                          icon: const Icon(Icons.star),
                          color:
                              selectedRating >= 5 ? Colors.yellow : Colors.grey,
                          onPressed: () => setState(() => selectedRating = 5),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          40,
                          145,
                          135,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Related Products Section
                    const Text(
                      '🛒 Related Products (mock)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 295,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 6,
                        padding: const EdgeInsets.only(top: 8),
                        itemBuilder:
                            (context, index) => Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              child: ProductDeck(
                                imageUrl:
                                    'assets/product${(index % 6) + 1}.jpg',
                                name: 'Product ${index + 1}',
                                brand: 'Brand ${index + 1}',
                                price: '999',
                                originalPrice: '1299',
                                onTap: () {},
                                onAddToCart: () {},
                                onWishlistToggle: () {},
                                isWishlisted: false,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
