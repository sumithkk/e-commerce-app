import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fashion_app/features/product/screens/product_detail.dart';
import 'package:fashion_app/features/product/screens/search_screen.dart';

class ProductSearchBar extends StatefulWidget {
  const ProductSearchBar({super.key});

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<dynamic> _searchResults = [];
  bool _isDropdownVisible = false;

  Future<void> fetchSearchResults(String term) async {
    if (term.isEmpty) {
      setState(() {
        _searchResults = [];
        _isDropdownVisible = false;
      });
      return;
    }

    final url = Uri.parse(
      'http://57.128.166.138:2000/api/v1/line/item/search?term=$term',
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
      final results = data['content'][0]['lineItems'] ?? [];
      setState(() {
        _searchResults = results;
        _isDropdownVisible = true;
      });
    } else {
      setState(() {
        _searchResults = [];
        _isDropdownVisible = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      fetchSearchResults(value);
    });
  }

  void _onSearchSubmit() {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(keyword: _controller.text),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Image.asset('assets/logo.png', width: 50, height: 50),
              ),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _onSearchSubmit(),
                    decoration: InputDecoration(
                      hintText: 'Search for products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _controller.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _controller.clear();
                                  fetchSearchResults('');
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 0.0, right: 0),
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    print("Notification icon clicked");
                  },
                ),
              ),
            ],
          ),
        ),
        if (_isDropdownVisible)
          Container(
            margin: EdgeInsets.only(top: 8),
            color: Colors.white,
            child: ListView.builder(
              shrinkWrap:
                  true, // Allow the list to take only the required space
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return _buildDropdownItem(product);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownItem(dynamic product) {
    // Fetch the thumbnail URL from the API response
    final thumbnailUrl =
        product['images']?.firstWhere(
          (image) => image['imageType'] == 'THUMBNAIL', // Filter for thumbnail
          orElse: () => {}, // If not found, return an empty object
        )['imageURI'] ??
        ''; // Fetch the image URI

    // Check if the thumbnail URL exists
    if (thumbnailUrl.isEmpty) {
      // If no thumbnail, use a placeholder image
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(productSlug: product['slug']),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              // Show a placeholder or fallback image if no thumbnail is available
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/product18.jpg', // Use a local placeholder image
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 16),
              // Product details with truncated name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['brand'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      product['name'] ?? '',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      overflow: TextOverflow.ellipsis, // Truncate the name
                      maxLines: 1, // Ensure single line truncation
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If thumbnail URL exists, display the image properly
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(productSlug: product['slug']),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail Image on the left if thumbnailUrl is available
            if (thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  thumbnailUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(width: 16),
            // Product details with truncated name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['brand'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product['name'] ?? '',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    overflow: TextOverflow.ellipsis, // Truncate the name
                    maxLines: 1, // Ensure single line truncation
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyFixedAppBarPage extends StatelessWidget {
  const MyFixedAppBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true, // This makes the app bar stay at the top
            expandedHeight: 80.0, // You can adjust this as needed
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero, // Remove default title padding
              title: ProductSearchBar(), // Embed your search bar here
              centerTitle: false,
            ),
          ),
          // Add the rest of your page content as SliverList or SliverGrid
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return ListTile(title: Text('Item #$index'));
              },
              childCount: 50, // Replace with your actual content count
            ),
          ),
        ],
      ),
    );
  }
}
