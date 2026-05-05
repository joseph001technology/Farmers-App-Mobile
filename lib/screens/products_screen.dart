import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedCategory = 'all';   // use backend slugs
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // label → backend slug
  final List<Map<String, String>> categories = [
    {'label': 'All',            'emoji': '🌿', 'slug': 'all'},
    {'label': 'Vegetables',     'emoji': '🥬', 'slug': 'vegetables'},
    {'label': 'Fruits',         'emoji': '🍎', 'slug': 'fruits'},
    {'label': 'Grains',         'emoji': '🌾', 'slug': 'grains'},
    {'label': 'Animal Products','emoji': '🥛', 'slug': 'animal_products'},
    {'label': 'Manure',         'emoji': '🌱', 'slug': 'manure'},
    {'label': 'Others',         'emoji': '📦', 'slug': 'others'},
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    setState(() { isLoading = true; errorMessage = ''; });
    try {
      final result = await ProductService.getProducts();
      setState(() { products = result; isLoading = false; });
    } catch (e) {
      setState(() { errorMessage = 'Connection error: $e'; isLoading = false; });
    }
  }

  List<Product> get filteredProducts {
    List<Product> result = products;

    // ── Category filter using backend slugs ─────────────────────────
    if (selectedCategory != 'all') {
      result = result.where((p) {
        final cat = p.category?.toLowerCase() ?? '';
        return cat == selectedCategory;
      }).toList();
    }

    // ── Live search ─────────────────────────────────────────────────
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        (p.categoryLabel.toLowerCase().contains(q)) ||
        (p.farmerName?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    return result;
  }

  String shortDescription(String text) {
    final words = text.split(' ');
    if (words.length <= 12) return text;
    return '${words.take(12).join(' ')}...';
  }

  @override
  Widget build(BuildContext context) {
    final cart   = Provider.of<CartProvider>(context);
    final displayed = filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Harvest",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              if (cart.totalItems > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(cart.totalItems.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => searchQuery = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search products, farmers…',
                hintStyle: GoogleFonts.poppins(fontSize: 14),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                        })
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${displayed.length} result${displayed.length == 1 ? '' : 's'} for "$searchQuery"',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ),

          // ── Category chips ────────────────────────────────────────
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final isSelected = selectedCategory == cat['slug'];
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat['slug']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green[700] : Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.green[700]! : Colors.green[200]!),
                    ),
                    child: Text(
                      '${cat['emoji']} ${cat['label']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.green[800],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // ── Product grid ──────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMessage,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: fetchProducts,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : displayed.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  searchQuery.isNotEmpty ? '🔍' :
                                  (selectedCategory == 'all' ? '🌿' :
                                   categories.firstWhere(
                                     (c) => c['slug'] == selectedCategory,
                                     orElse: () => {'emoji': '📦'})['emoji']!),
                                  style: const TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  searchQuery.isNotEmpty
                                      ? 'No results for "$searchQuery"'
                                      : 'No ${categories.firstWhere((c) => c['slug'] == selectedCategory, orElse: () => {'label': selectedCategory})['label']} available',
                                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                                if (searchQuery.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => searchQuery = '');
                                    },
                                    child: Text('Clear search',
                                        style: GoogleFonts.poppins(color: Colors.green[700])),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchProducts,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: GridView.builder(
                                itemCount: displayed.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.70,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemBuilder: (context, index) {
                                  final product = displayed[index];
                                  return GestureDetector(
                                    onTap: () => Navigator.push(context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailScreen(product: product))),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: Offset(0, 2))
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Image
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                        top: Radius.circular(14)),
                                                child: product.imageUrl != null &&
                                                        product.imageUrl!.isNotEmpty
                                                    ? Image.network(
                                                        product.imageUrl!,
                                                        height: 110,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (c, e, s) =>
                                                            _imgPlaceholder(),
                                                      )
                                                    : _imgPlaceholder(),
                                              ),
                                              // Category badge
                                              if (product.categoryLabel.isNotEmpty)
                                                Positioned(
                                                  top: 6, left: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[700]!
                                                          .withOpacity(0.85),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      product.categoryLabel,
                                                      style: GoogleFonts.poppins(
                                                          fontSize: 9,
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),

                                          // Info
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(product.name,
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis),
                                                if (product.farmerName != null)
                                                  Text('by ${product.farmerName}',
                                                      style: GoogleFonts.poppins(
                                                          fontSize: 10,
                                                          color: Colors.green[600]),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis),
                                                Text(
                                                  'KSh ${product.price.toStringAsFixed(0)}',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: Colors.green[800],
                                                      fontWeight: FontWeight.bold),
                                                ),
                                                // Stars
                                                if (product.averageRating != null &&
                                                    product.averageRating! > 0)
                                                  Row(
                                                    children: [
                                                      ...List.generate(5, (i) => Icon(
                                                        i < product.averageRating!.floor()
                                                            ? Icons.star_rounded
                                                            : (i < product.averageRating!
                                                                ? Icons.star_half_rounded
                                                                : Icons.star_outline_rounded),
                                                        color: Colors.amber,
                                                        size: 12,
                                                      )),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        product.averageRating!
                                                            .toStringAsFixed(1),
                                                        style: GoogleFonts.poppins(
                                                            fontSize: 9,
                                                            color: Colors.grey[600]),
                                                      ),
                                                    ],
                                                  )
                                                else
                                                  Text(
                                                    shortDescription(product.description),
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        color: Colors.grey[600]),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                const SizedBox(height: 4),
                                                // Add to cart
                                                Align(
                                                  alignment: Alignment.centerRight,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      cart.addToCart(product);
                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(SnackBar(
                                                        content: Text(
                                                            '${product.name} added 🛒'),
                                                        duration: const Duration(
                                                            seconds: 1),
                                                        backgroundColor:
                                                            Colors.green[700],
                                                        behavior:
                                                            SnackBarBehavior.floating,
                                                      ));
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.all(7),
                                                      decoration: BoxDecoration(
                                                          color: Colors.green[700],
                                                          shape: BoxShape.circle),
                                                      child: const Icon(Icons.add,
                                                          color: Colors.white,
                                                          size: 18),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        height: 110,
        color: Colors.green[50],
        child: const Center(
            child: Icon(Icons.grass, color: Colors.green, size: 36)),
      );
}