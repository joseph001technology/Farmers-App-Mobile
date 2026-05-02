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
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> categories = [
    {'label': 'All', 'emoji': '🌿'},
    {'label': 'Vegetables', 'emoji': '🥬'},
    {'label': 'Fruits', 'emoji': '🍎'},
    {'label': 'Grains', 'emoji': '🌾'},
    {'label': 'Animal Products', 'emoji': '🥛'},
    {'label': 'Manure', 'emoji': '🌱'},
    {'label': 'Others', 'emoji': '📦'},
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
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await ProductService.getProducts();
      setState(() {
        products = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Connection error: $e";
        isLoading = false;
      });
    }
  }

  List<Product> get filteredProducts {
    List<Product> result = products;

    // Filter by category — prefer the real category field, fallback to name matching
    if (selectedCategory != 'All') {
      result = result.where((p) {
        // Use real category field if available
        if (p.category != null && p.category!.isNotEmpty) {
          return p.category!.toLowerCase() ==
              selectedCategory.toLowerCase();
        }
        // Fallback: name-based heuristic
        final name = p.name.toLowerCase();
        switch (selectedCategory) {
          case 'Vegetables':
            return name.contains('carrot') ||
                name.contains('tomato') ||
                name.contains('cabbage') ||
                name.contains('spinach') ||
                name.contains('kale') ||
                name.contains('onion') ||
                name.contains('pepper') ||
                name.contains('vegetable');
          case 'Fruits':
            return name.contains('mango') ||
                name.contains('banana') ||
                name.contains('apple') ||
                name.contains('orange') ||
                name.contains('avocado') ||
                name.contains('fruit');
          case 'Grains':
            return name.contains('maize') ||
                name.contains('wheat') ||
                name.contains('rice') ||
                name.contains('grain') ||
                name.contains('sorghum') ||
                name.contains('millet') ||
                name.contains('potato');
          case 'Animal Products':
            return name.contains('milk') ||
                name.contains('egg') ||
                name.contains('meat') ||
                name.contains('honey') ||
                name.contains('chicken') ||
                name.contains('beef');
          case 'Manure':
            return name.contains('manure') ||
                name.contains('compost') ||
                name.contains('fertilizer');
          default:
            return true;
        }
      }).toList();
    }

    // Live search filter — searches name and description
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            (p.category?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }

  String shortDescription(String text) {
    final words = text.split(' ');
    if (words.length <= 15) return text;
    return '${words.take(15).join(' ')}...';
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final displayed = filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Today's Harvest",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cart.totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      cart.totalItems.toString(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),

      body: Column(
        children: [
          // 🔍 Search bar — now LIVE, not readOnly
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => searchQuery = value.trim());
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Search products...",
                hintStyle: GoogleFonts.poppins(fontSize: 14),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Search result count
          if (searchQuery.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${displayed.length} result${displayed.length == 1 ? '' : 's'} for \"$searchQuery\"",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ),

          // 📦 Category chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedCategory = cat['label']!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green[700]
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.green[700]!
                            : Colors.green[200]!,
                      ),
                    ),
                    child: Text(
                      "${cat['emoji']} ${cat['label']}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color:
                            isSelected ? Colors.white : Colors.green[800],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 🔥 Products grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMessage,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchProducts,
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    : displayed.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  searchQuery.isNotEmpty
                                      ? '🔍'
                                      : (selectedCategory == 'All'
                                          ? '🌿'
                                          : categories.firstWhere((c) =>
                                              c['label'] ==
                                              selectedCategory)['emoji']!),
                                  style: const TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  searchQuery.isNotEmpty
                                      ? "No results for \"$searchQuery\""
                                      : "No $selectedCategory available",
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey[600]),
                                ),
                                if (searchQuery.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => searchQuery = '');
                                    },
                                    child: Text("Clear search",
                                        style: GoogleFonts.poppins(
                                            color: Colors.green[700])),
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
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemBuilder: (context, index) {
                                  final product = displayed[index];

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(
                                              product: product),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 3,
                                            offset: Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius
                                                        .vertical(
                                                        top: Radius.circular(
                                                            12)),
                                                child: product.imageUrl !=
                                                            null &&
                                                        product.imageUrl!
                                                            .isNotEmpty
                                                    ? Image.network(
                                                        product.imageUrl!,
                                                        height: 110,
                                                        width:
                                                            double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            Container(
                                                          height: 110,
                                                          color: Colors
                                                              .green[100],
                                                          child: const Center(
                                                            child: Icon(
                                                                Icons.image,
                                                                color: Colors
                                                                    .green),
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        height: 110,
                                                        color:
                                                            Colors.green[100],
                                                        child: const Center(
                                                          child: Icon(
                                                              Icons.grass,
                                                              color: Colors
                                                                  .green),
                                                        ),
                                                      ),
                                              ),
                                              // Category badge
                                              if (product.category != null &&
                                                  product.category!.isNotEmpty)
                                                Positioned(
                                                  top: 6,
                                                  left: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[700]!
                                                          .withOpacity(0.85),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      product.category!,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 9,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Positioned(
                                                right: 6,
                                                top: 6,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              "Wishlist coming soon")),
                                                    );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.favorite_border,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style:
                                                      GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "KSh ${product.price.toStringAsFixed(0)}",
                                                  style:
                                                      GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color: Colors.green[800],
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                                // Rating stars
                                                if (product.averageRating !=
                                                        null &&
                                                    product.averageRating! > 0)
                                                  Row(
                                                    children: [
                                                      ...List.generate(
                                                        5,
                                                        (i) => Icon(
                                                          i <
                                                                  product
                                                                      .averageRating!
                                                                      .floor()
                                                              ? Icons
                                                                  .star_rounded
                                                              : (i <
                                                                      product
                                                                          .averageRating!
                                                                  ? Icons
                                                                      .star_half_rounded
                                                                  : Icons
                                                                      .star_outline_rounded),
                                                          color: Colors.amber,
                                                          size: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        product.averageRating!
                                                            .toStringAsFixed(1),
                                                        style: GoogleFonts
                                                            .poppins(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .grey[600]),
                                                      ),
                                                    ],
                                                  )
                                                else
                                                  Text(
                                                    shortDescription(
                                                        product.description),
                                                    style:
                                                        GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                const SizedBox(height: 6),

                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: GestureDetector(
                                                    behavior:
                                                        HitTestBehavior
                                                            .opaque,
                                                    onTap: () {
                                                      cart.addToCart(product);
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              "${product.name} added 🛒"),
                                                          duration:
                                                              const Duration(
                                                                  seconds: 1),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .all(8),
                                                      decoration:
                                                          BoxDecoration(
                                                        color:
                                                            Colors.green[700],
                                                        shape:
                                                            BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.add,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
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
}