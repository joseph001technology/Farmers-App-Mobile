import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';
import 'payment_screen.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _paymentMethod = 'mpesa';
  List<Product> _suggestedProducts = [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _loadingSuggestions = true);
    try {
      final all = await ProductService.getProducts();
      setState(() {
        _suggestedProducts = all.take(8).toList();
        _loadingSuggestions = false;
      });
    } catch (_) {
      setState(() => _loadingSuggestions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text("My Cart 🛒",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: Text("Clear",
                  style: GoogleFonts.poppins(
                      color: Colors.red[400], fontSize: 13)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _emptyCartView()
          : _cartWithItems(context, cart),
    );
  }

  // ── EMPTY CART ─────────────────────────────────────────────────────
  Widget _emptyCartView() {
    return ListView(
      children: [
        // Hero empty state
        Container(
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[700]!, Colors.teal[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text("🛒", style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              Text(
                "Your cart is empty",
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                "Fresh produce is waiting for you!\nStart adding items below 👇",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Fresh Picks 🌽",
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              Text("Scroll to explore →",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal product scroll
        SizedBox(
          height: 220,
          child: _loadingSuggestions
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green))
              : _suggestedProducts.isEmpty
                  ? Center(
                      child: Text("No products found",
                          style: GoogleFonts.poppins(
                              color: Colors.grey[500])))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _suggestedProducts.length,
                      itemBuilder: (context, index) {
                        final product = _suggestedProducts[index];
                        return _suggestedProductCard(product);
                      },
                    ),
        ),

        const SizedBox(height: 24),

        // Why shop prompt
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                const Text("🚚", style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Same-day delivery",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                          "Order before noon — get fresh produce by evening.",
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Text("🌱", style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("100% Organic",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("No pesticides. Straight from the farm.",
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _suggestedProductCard(Product product) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (product.farmerName != null)
                    Text("by ${product.farmerName}",
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.green[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "KSh ${product.price.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () {
                          cart.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${product.name} added 🛒",
                                  style: GoogleFonts.poppins()),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green[700],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      height: 110,
      color: Colors.green[50],
      child:
          const Center(child: Icon(Icons.grass, color: Colors.green, size: 36)),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Clear Cart?",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Remove all items from your cart?",
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel",
                  style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[500],
                foregroundColor: Colors.white),
            child: Text("Clear", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // ── CART WITH ITEMS ────────────────────────────────────────────────
  Widget _cartWithItems(BuildContext context, CartProvider cart) {
    return Column(
      children: [
        // Items list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Item count header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "${cart.items.length} item${cart.items.length == 1 ? '' : 's'} in your cart",
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              ...cart.items.values.map((item) => _cartItemTile(context, cart, item)),
            ],
          ),
        ),

        // Checkout panel
        _checkoutPanel(context, cart),
      ],
    );
  }

  Widget _cartItemTile(BuildContext context, CartProvider cart, dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.product.imageUrl != null &&
                      item.product.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.product.imageUrl!,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _cartImgPlaceholder(),
                    )
                  : _cartImgPlaceholder(),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (item.product.farmerName != null)
                    Text("by ${item.product.farmerName}",
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.green[600])),
                  const SizedBox(height: 2),
                  Text(
                    "KSh ${item.product.price.toStringAsFixed(0)} × ${item.quantity}",
                    style: GoogleFonts.poppins(
                        color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    "KSh ${(item.product.price * item.quantity).toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),

            // Qty controls + delete
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _qtyBtn(
                        Icons.remove,
                        Colors.grey[100]!,
                        Colors.green,
                        () => cart.decreaseQty(item.product.id)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(item.quantity.toString(),
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    _qtyBtn(
                        Icons.add,
                        Colors.green[700]!,
                        Colors.white,
                        () => cart.increaseQty(item.product.id)),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => cart.removeItem(item.product.id),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.delete_outline, color: Colors.red[400], size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(
      IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  Widget _cartImgPlaceholder() {
    return Container(
      width: 65,
      height: 65,
      color: Colors.green[50],
      child: const Center(
          child: Icon(Icons.grass, color: Colors.green, size: 28)),
    );
  }

  Widget _checkoutPanel(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment method
          Text("Payment Method",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              _paymentOption('mpesa', '📱', 'M-Pesa', 'Pay now via STK push'),
              const SizedBox(width: 10),
              _paymentOption(
                  'pod', '💵', 'Pay on Delivery', 'Cash when it arrives'),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total",
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey[600])),
              Text(
                "KSh ${cart.totalPrice.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800]),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Checkout button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _checkout(context, cart),
              icon: Icon(
                _paymentMethod == 'pod'
                    ? Icons.local_shipping_outlined
                    : Icons.shopping_bag_outlined,
              ),
              label: Text(
                _paymentMethod == 'pod'
                    ? "Place Order (Pay on Delivery)"
                    : "Checkout via M-Pesa",
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _paymentMethod == 'pod'
                    ? Colors.orange[600]
                    : Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(
      String value, String emoji, String label, String subtitle) {
    final isSelected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.green[600]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(label,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isSelected
                                ? Colors.green[800]
                                : Colors.grey[800])),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: Colors.green[600], size: 16),
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkout(BuildContext context, CartProvider cart) async {
    final items = cart.items.values
        .map((item) => {
              "product": item.product.id,
              "quantity": item.quantity,
            })
        .toList();

    try {
      final response = await ApiService.post("/orders/", {
        "items": items,
        "payment_method": _paymentMethod,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orderId = data['id'];
        final totalPrice =
            double.tryParse(data['total_price'].toString()) ??
                cart.totalPrice;

        cart.clearCart();

        if (!context.mounted) return;

        if (_paymentMethod == 'pod') {
          // ✅ FIX: Use pushAndRemoveUntil so the screen stack is clean
          // This prevents the black/white blank screen after POD order
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Order #$orderId placed! Pay KSh ${totalPrice.toStringAsFixed(0)} on delivery 🚚",
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ]),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          // Navigate to Orders screen so user can see their order
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OrdersScreen()),
            (route) => route.isFirst, // keep home underneath
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                orderId: orderId,
                totalPrice: totalPrice,
              ),
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error placing order: $e")),
      );
    }
  }
}