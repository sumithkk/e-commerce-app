import 'package:flutter/material.dart';

// Rating Widget
class RatingWidget extends StatelessWidget {
  final String itemId; // The product/item ID to fetch the rating
  final double size; // Size of the stars
  final double rating; // Rating value from the API
  final int totalReviews; // Total number of reviews

  // Updated constructor with rating and totalReviews parameters
  RatingWidget({
    required this.itemId,
    this.size = 16, // Default size is 16 for compact size
    required this.rating,
    required this.totalReviews,
    Key? key,
  }) : super(key: key);

  // Function to display filled and unfilled stars based on rating
  Widget buildStars() {
    int fullStars = rating.toInt(); // Number of filled stars
    double fractionalStar = rating - fullStars;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index < fullStars + 1 && fractionalStar > 0) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: size);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        buildStars(), // Display the stars
        const SizedBox(width: 4),
        Text(
          "($totalReviews reviews)", // Display total reviews
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
