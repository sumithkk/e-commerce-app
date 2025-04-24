import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    fetchProductDetail();
  }

  Future<void> fetchProductDetail() async {
    final url = Uri.parse(
      'http://57.128.166.138:2000/api/v1/line/item/term/${widget.productSlug}',
    );
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'isGuest': 'true',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      const encoder = JsonEncoder.withIndent('  ');
      debugPrint("📦 [PDP API] Status: ${response.statusCode}");
      debugPrint("📝 [PDP API] Formatted Body:\n${encoder.convert(data)}");

      setState(() {
        product = data;
        images = data['images'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load product details')),
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

  Future<void> addToWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null || product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to add to wishlist')),
      );
      return;
    }

    final requestBody = {'customer': userId, 'item': product!['id']};
    debugPrint("📤 [Wishlist API] Request: ${jsonEncode(requestBody)}");

    final prodId = product!['id'];

    final url = Uri.parse(
      'http://57.128.166.138:2000/api/v1/wishlist/customer/$userId/item/$prodId',
    );
    final response = await http.post(url);

    debugPrint("📦 [Wishlist API] Url: $url");
    debugPrint("🛍️ [Wishlist API] Response Body: ${response.statusCode}");
    debugPrint("🛍️ [Wishlist API] Response Body: ${response.body}");

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

  void addToCart() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to cart (mock logic)')));
  }

  @override
  Widget build(BuildContext context) {
    final options = product?['productOptions'] as List<dynamic>? ?? [];
    final breadcrumbs = product?['breadcrumbs'] as List<dynamic>? ?? [];
    final isStockStatus = product?['isStockStatus'] ?? false;
    final discount = product?['discount'];

    return Scaffold(
      appBar: AppBar(
        title: Text(product?['name'] ?? 'Product Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: addToWishlist,
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
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          breadcrumbs.map((crumb) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  crumb['label'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Text(
                                  " > ",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 12),
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
                                "${discount}% OFF",
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
                    const SizedBox(height: 16),
                    Text(
                      product!['brand'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product!['name'],
                      style: const TextStyle(
                        fontSize: 20,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed:
                              () => setState(
                                () => quantity > 1 ? quantity-- : quantity,
                              ),
                        ),
                        Text('$quantity', style: const TextStyle(fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => quantity++),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.green,
                          ),
                          onPressed: addToCart,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          options.map((opt) {
                            final isColorOption = opt['values'].any(
                              (val) => val['colorImage'] != null,
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                isColorOption
                                    ? Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: List<Widget>.from(
                                        (opt['values'] as List).map((val) {
                                          final img =
                                              val['colorImage']?['imageURI'];
                                          return GestureDetector(
                                            onTap:
                                                () => changeImageBasedOnColor(
                                                  img,
                                                ),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                              .map<DropdownMenuItem<String>>((
                                                val,
                                              ) {
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
                    ),
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
                    const Text(
                      '🛒 Related Products (mock)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder:
                            (context, index) => Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12, top: 8),
                              color: Colors.grey[200],
                              child: const Center(child: Text('Product')),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
