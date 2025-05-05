import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fashion_app/widgets/product_deck.dart';
import 'package:fashion_app/widgets/searchBar.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<String> banners = [
    'assets/banner1.jpg',
    'assets/banner2.jpg',
    'assets/banner3.jpg',
    'assets/banner4.jpg',
    'assets/banner5.jpg',
  ];

  final List<Map<String, String>> products = [
    {
      "name": "Nike Running Shoes for men",
      "brand": "Nike",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product1.jpg",
    },
    {
      "name": "Nikon Camera - D7000 - Mirror less",
      "brand": "Nikon",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product2.jpg",
    },
    {
      "name": "Nyka Lipstick combo pack - Red",
      "brand": "Brand 3",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product3.jpg",
    },
    {
      "name": "Lee cooper Mountain Bag - Extreme tuff",
      "brand": "Lee",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product4.jpg",
    },
    {
      "name": "Beats audio wireless headphone ",
      "brand": "Beats",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product5.jpg",
    },
    {
      "name": "Apple iPhone 18 Pro Max 128Gb",
      "brand": "Apple",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product6.jpg",
    },
  ];

  final List<Map<String, String>> bestSellers = [
    {
      "name": "Bamboo stick long lasting candles",
      "brand": "WoodRose",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product7.jpg",
    },
    {
      "name": "Apple iPhone 16 pro 256gb",
      "brand": "Apple",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product8.jpg",
    },
    {
      "name": "Dove Anti-hairfall Shampoo",
      "brand": "Dove",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product9.jpg",
    },
    {
      "name": "Nyka Body serum 150ml",
      "brand": "Nyka",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product10.jpg",
    },
    {
      "name": "Adidas Running Shoes for men",
      "brand": "Adidas",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product11.jpg",
    },
    {
      "name": "RayBan eyeglass / Sunglass",
      "brand": "RayBan",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product12.jpg",
    },
  ];

  final List<Map<String, String>> quickPicks = [
    {
      "name": "LensBaby 200mm Lens",
      "brand": "lensBaby",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product13.jpg",
    },
    {
      "name": "Brand Face Cream 200ml",
      "brand": "Brand",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product14.jpg",
    },
    {
      "name": "David Off Perfume for men",
      "brand": "David Off",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product15.jpg",
    },
    {
      "name": "Lemon Facewash for women 200ml",
      "brand": "Lemon",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product17.jpg",
    },
    {
      "name": "CareMakes Herbal vitamin tablets",
      "brand": "CareMakes",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product18.jpg",
    },
    {
      "name": "ManCompany Beard Serum",
      "brand": "ManCompany",
      "price": "999",
      "originalPrice": "1299",
      "imageUrl": "assets/product16.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildDeliveryStrip(),
              _buildBannerCarousel(),
              _buildSection("New Arrivals"),
              _buildProductDeck(products),
              _buildSection("Best Sellers"),
              _buildProductDeck(bestSellers),
              _buildSection("Quick Picks"),
              _buildProductDeck(quickPicks),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const ProductSearchBar(); // Replaces the old header
  }

  Widget _buildDeliveryStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Colors.teal.shade50,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.location_on_outlined, color: Colors.teal, size: 18),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              "Delivery in 4 hours · Now delivering across Kolkata!",
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: CarouselSlider.builder(
        itemCount: banners.length,
        itemBuilder: (context, index, realIdx) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              banners[index],
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          );
        },
        options: CarouselOptions(
          height: 180,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 1,
          aspectRatio: 16 / 9,
          initialPage: 0,
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProductDeck(List<Map<String, String>> productList) {
    return SizedBox(
      height: 302,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: productList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final p = productList[index];
          return SizedBox(
            width: 160,
            child: ProductDeck(
              imageUrl: p['imageUrl'],
              name: p['name']!,
              brand: p['brand'],
              price: p['price']!,
              originalPrice: p['originalPrice'],
              isWishlisted: false,
              onTap: () {},
              onAddToCart: () {},
              onWishlistToggle: () {},
            ),
          );
        },
      ),
    );
  }
}
