import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fashion_app/features/product/screens/product_detail.dart';

class SearchHeader extends StatefulWidget {
  const SearchHeader({super.key});

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<dynamic> suggestions = [];
  bool isLoading = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.isNotEmpty)
        fetchSuggestions(query);
      else
        setState(() => suggestions = []);
    });
  }

  Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      "http://16.171.147.184:2000/api/v1/search/term/$query",
    );
    final response = await http.get(url, headers: {"isGuest": "true"});

    debugPrint("\u{1F4EC} [Account] Status: ${response.statusCode}");
    debugPrint("\u{1F4C4} [Account] Body: ${jsonEncode(response.body)}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['content']?[0]?['lineItems'] ?? [];
      return List<Map<String, dynamic>>.from(items);
    } else {
      return [];
    }
  }

  void navigateToProduct(String slug) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(productSlug: slug)),
    );
    _controller.clear();
    setState(() => suggestions = []);
  }

  void navigateToSearchPage() {
    // Add navigation to full search results page
    // Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultsPage(term: _controller.text)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Full search page not implemented yet")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Delivery + Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Delivering to",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Text(
                "Kolkata",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => navigateToSearchPage(),
                decoration: InputDecoration(
                  hintText: "Search products",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      isLoading
                          ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : _controller.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() => suggestions = []);
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Suggestions Dropdown
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return ListTile(
                  dense: true,
                  leading:
                      item['image'] != null
                          ? Image.network(
                            item['image'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.image, size: 40),
                  title: Text(item['name']),
                  onTap: () => navigateToProduct(item['slug']),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
