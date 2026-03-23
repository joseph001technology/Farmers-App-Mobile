import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';              // ← import the model
import 'product_detail_screen.dart';         // ← your detail screen

// Fake / dummy products (only here for now – later replaced with API data)
final List<Product> dummyProducts = [
  Product(
    id: '1',
    name: 'Sukuma Wiki (Kale)',
    price: 50.0,
    unit: 'per bunch',
    description: 'Freshly harvested organic sukuma wiki from my Nairobi farm. Tender leaves, perfect for your daily greens.',
    imageUrl:
        'https://greenspoon.co.ke/wp-content/uploads/2021/09/Greenspoon-1087-1400x932.jpg',
  ),
  Product(
    id: '2',
    name: 'Organic Tomatoes',
    price: 120.0,
    unit: 'per kg',
    description: 'Juicy, vine-ripened tomatoes grown without chemicals. Great for salads, stews & sauces.',
    imageUrl:
        'https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEi8L0Anhz3Shloqdh-zSAByoEjBKwgG-ej5R3Z0TMKEgZZL1TETn5_IyCDcKza9cX_nQCcCjEy1JR1q65vf5aSK6-dvvL0cERWugA9c7U4oBa4ZIQvuO-QBzbh8YWPR3PRkLtfQuvFlg9AQBVd6xW-kvIsJoLJ7qRHK_NgqnjY2kqOR9k_eTCRM2wiKdC4Z/s2000/cherry-tomato-farming-in-kenya.webp',
  ),
  Product(
    id: '3',
    name: 'Hass Avocados',
    price: 80.0,
    unit: 'per piece',
    description: 'Creamy, nutrient-rich Hass avocados straight from the tree. Ready to eat or for guacamole!',
    imageUrl:
        'https://www.freshelaexporters.com/wp-content/uploads/2021/12/avocado-4-1.jpeg',
  ),
  Product(
    id: '4',
    name: 'Fresh Spinach',
    price: 60.0,
    unit: 'per bunch',
    description: 'Tender organic spinach leaves – packed with iron and vitamins.',
    imageUrl:
        'https://m.media-amazon.com/images/I/81Ez6HDm6GL.jpg',
  ),
  Product(
    id: '5',
    name: 'Organic Carrots',
    price: 70.0,
    unit: 'per kg',
    description: 'Sweet, crunchy carrots pulled fresh today. Ideal for juices or cooking.',
    imageUrl:
        'https://thumbs.dreamstime.com/b/harvesting-fresh-organic-carrots-soil-hands-pulling-vegetables-gardening-farming-agriculture-concept-harvesting-fresh-organic-328100364.jpg',
  ),
  Product(
    id: '6',
    name: 'Mangoes (Seasonal)',
    price: 150.0,
    unit: 'per kg',
    description: 'Sweet Kenyan mangoes when in season – juicy and full of flavor.',
    imageUrl:
        'https://d3fwccq2bzlel7.cloudfront.net/Pictures/1024x536/3/1/8/29318_2_1200763.jpg',
  ),
];

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Harvest", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: dummyProducts.length,
          itemBuilder: (context, index) {
            final product = dummyProducts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                );
              },
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        product.imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 140,
                          color: Colors.green[100],
                          child: const Icon(Icons.image_not_supported, size: 60, color: Colors.green),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "KSh ${product.price.toStringAsFixed(0)} ${product.unit}",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product.description,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Provider.of<CartProvider>(context, listen: false)
                                    .addToCart(product);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("${product.name} added to cart 🛒")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Add to Cart", style: TextStyle(color: Colors.white, fontSize: 13)),
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
    );
  }
}