import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String price;
  final String? originalPrice;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onWishlistToggle;
  final bool isWishlisted;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.onTap,
    required this.onAddToCart,
    required this.onWishlistToggle,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = originalPrice != null && originalPrice != price;

    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹$price",
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: IconButton(
                          icon: const Icon(Icons.add_shopping_cart, size: 14),
                          color: Colors.white,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minHeight: 24,
                            minWidth: 24,
                          ),
                          onPressed: onAddToCart,
                        ),
                      ),
                    ),
                  ],
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
