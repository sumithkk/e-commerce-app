import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductCard extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String price;
  final String? originalPrice;
  final String? brand;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onWishlistToggle;
  final bool isWishlisted;
  final String itemId; // Added to pass itemId for ratings

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    this.originalPrice,
    this.brand,
    required this.onTap,
    required this.onAddToCart,
    required this.onWishlistToggle,
    this.isWishlisted = false,
    required this.itemId, // itemId for fetching the rating
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = originalPrice != null && originalPrice != price;

    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Discount and Wishlist Icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child:
                      imageUrl != null
                          ? Image.network(
                            imageUrl!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                          : Container(
                            height: 140,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${_calculateDiscount()}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: Colors.pink,
                      size: 20,
                    ),
                    onPressed: onWishlistToggle,
                  ),
                ),
              ],
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand != null)
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // Align to the right
                      children: [
                        Text(
                          brand!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        RatingWidget(
                          itemId: itemId,
                          size: 16, // Smaller size for the rating widget
                        ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "₹$price",
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (hasDiscount)
                        Text(
                          "₹$originalPrice",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: Colors.teal),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: onAddToCart,
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    size: 16,
                    color: Colors.teal,
                  ),
                  label: const Text(
                    "Add to Cart",
                    style: TextStyle(color: Colors.teal, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateDiscount() {
    final orig = double.tryParse(originalPrice ?? '') ?? 0;
    final sale = double.tryParse(price) ?? 0;
    if (orig <= 0 || sale <= 0 || orig <= sale) return 0;
    return (((orig - sale) / orig) * 100).round();
  }
}

// Rating Widget
class RatingWidget extends StatefulWidget {
  final String itemId; // The product/item ID to fetch the rating
  final double size; // Size of the stars

  RatingWidget({required this.itemId, this.size = 20, Key? key})
    : super(key: key);

  @override
  _RatingWidgetState createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  double _rating = 0.0;

  // Fetch the rating data from the API
  Future<void> fetchRating() async {
    final url = Uri.parse(
      'http://16.171.147.184:2000/api/v1/ratings/line-item/${widget.itemId}?size=100&page=1',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rating = data['overallRating']['rating'].toDouble();
        });
      } else {
        print("Error fetching rating data");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRating();
  }

  // Function to display filled and unfilled stars based on rating
  Widget buildStars() {
    int fullStars = _rating.toInt(); // Number of filled stars
    double fractionalStar = _rating - fullStars;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.amber, size: widget.size);
        } else if (index < fullStars + 1 && fractionalStar > 0) {
          return Icon(Icons.star_half, color: Colors.amber, size: widget.size);
        } else {
          return Icon(
            Icons.star_border,
            color: Colors.amber,
            size: widget.size,
          );
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildStars();
  }
}
