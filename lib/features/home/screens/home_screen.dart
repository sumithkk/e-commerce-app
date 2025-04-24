import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fashion_app/models/product_model.dart';
import 'package:fashion_app/core/widgets/product_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy product data
    final List<ProductModel> newArrivals = [
      ProductModel(
        name: 'Striped Shirt',
        imageUrl: 'https://unsplash.it/150/200?image=1027',
        price: 999.0,
      ),
      ProductModel(
        name: 'Denim Jacket',
        imageUrl: 'https://unsplash.it/150/200?image=1062',
        price: 1799.0,
      ),
      ProductModel(
        name: 'Casual Dress',
        imageUrl: 'https://unsplash.it/150/200?image=1084',
        price: 1499.0,
      ),
    ];

    final List<ProductModel> bestsellers = [
      ProductModel(
        name: 'Linen Kurta',
        imageUrl: 'https://unsplash.it/150/200?image=1036',
        price: 1299.0,
      ),
      ProductModel(
        name: 'Slim Jeans',
        imageUrl: 'https://unsplash.it/150/200?image=1011',
        price: 1399.0,
      ),
      ProductModel(
        name: 'Printed Tee',
        imageUrl: 'https://unsplash.it/150/200?image=1038',
        price: 799.0,
      ),
    ];

    final List<ProductModel> quickPicks = [
      ProductModel(
        name: 'Oversized Hoodie',
        imageUrl: 'https://unsplash.it/150/200?image=1021',
        price: 1199.0,
      ),
      ProductModel(
        name: 'Cargo Pants',
        imageUrl: 'https://unsplash.it/150/200?image=1005',
        price: 1499.0,
      ),
      ProductModel(
        name: 'Tie-Dye Shirt',
        imageUrl: 'https://unsplash.it/150/200?image=1040',
        price: 899.0,
      ),
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivering to',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kolkata',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO: implement search
                  },
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Delivery Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Delivery in 4 Hours • Now delivering across Kolkata!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Carousel
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 160,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.85,
                      autoPlayInterval: const Duration(seconds: 3),
                    ),
                    items:
                        ['New Drops!', 'Big Sale', 'Limited Time Offer'].map((
                          text,
                        ) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                  ),

                  // Product Sections
                  ProductSection(title: 'New Arrivals', products: newArrivals),
                  ProductSection(title: 'Bestsellers', products: bestsellers),
                  ProductSection(title: 'Quick Picks', products: quickPicks),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
