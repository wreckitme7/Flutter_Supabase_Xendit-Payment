import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_model.dart';
import 'payment_service.dart';
import 'webview_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PaymentService _paymentService = PaymentService();
  
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final response = await _supabase.from('products').select();
    return (response as List).map((map) => Product.fromMap(map)).toList();
  }

  Future<void> _buyProduct(Product product) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final externalId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    
    final invoiceData = await _paymentService.createInvoice(
      externalId: externalId,
      amount: product.price,
      payerEmail: 'customer@example.com',
      description: 'Payment for ${product.name}',
    );

    Navigator.pop(context);

    if (invoiceData != null && invoiceData['invoice_url'] != null) {
      final invoiceUrl = invoiceData['invoice_url'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebviewScreen(invoiceUrl: invoiceUrl),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create payment invoice.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Shop')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Image.network(
                    product.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('₱${product.price.toStringAsFixed(2)}'),
                  trailing: ElevatedButton(
                    onPressed: () => _buyProduct(product),
                    child: const Text('Buy'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}