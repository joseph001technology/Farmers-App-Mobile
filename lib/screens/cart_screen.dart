import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text("My Cart",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.green[200]),
                  const SizedBox(height: 16),
                  Text("Your cart is empty",
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text("Add some fresh products!",
                      style:
                          GoogleFonts.poppins(color: Colors.grey[500])),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: cart.items.values.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: item.product.imageUrl != null &&
                                        item.product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        item.product.imageUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (c, e, s) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.green[100],
                                          child: const Icon(Icons.grass,
                                              color: Colors.green),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.green[100],
                                        child: const Icon(Icons.grass,
                                            color: Colors.green),
                                      ),
                              ),
                              const SizedBox(width: 12),

                              // Name + price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    Text(
                                      "KSh ${item.product.price.toStringAsFixed(0)} x ${item.quantity}",
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontSize: 12),
                                    ),
                                    Text(
                                      "KSh ${(item.product.price * item.quantity).toStringAsFixed(0)}",
                                      style: GoogleFonts.poppins(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),

                              // Qty controls
                              Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => cart
                                            .decreaseQty(item.product.id),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.green.shade200),
                                          ),
                                          child: const Icon(Icons.remove,
                                              size: 16,
                                              color: Colors.green),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          item.quantity.toString(),
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => cart
                                            .increaseQty(item.product.id),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[700],
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.add,
                                              size: 16,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () =>
                                        cart.removeItem(item.product.id),
                                    child: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // 🔥 Total + Checkout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total",
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.grey[700])),
                          Text(
                            "KSh ${cart.totalPrice.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final cartProvider = Provider.of<CartProvider>(
                                context,
                                listen: false);

                            final items =
                                cartProvider.items.values.map((item) {
                              return {
                                "product": item.product.id,
                                "quantity": item.quantity,
                              };
                            }).toList();

                            try {
                              // Step 1: Create order
                              final response = await ApiService.post("/orders/", {
                                "items": items,
                              });

                              if (response.statusCode == 201 ||
                                  response.statusCode == 200) {
                                final data = jsonDecode(response.body);
                                final orderId = data['id'];
                                final totalPrice = double.tryParse(
                                        data['total_price'].toString()) ??
                                    cartProvider.totalPrice;

                                cartProvider.clearCart();

                                if (!context.mounted) return;

                                // Step 2: Go to payment screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentScreen(
                                      orderId: orderId,
                                      totalPrice: totalPrice,
                                    ),
                                  ),
                                );
                              } else {
                                final error = jsonDecode(response.body);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(error.toString())),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: Text("Checkout",
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}