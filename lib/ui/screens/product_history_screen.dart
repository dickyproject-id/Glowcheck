import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models/skincare_model.dart';
import '../../providers/app_provider.dart';
import 'edit_product_screen.dart';

class ProductHistoryScreen extends StatefulWidget {
  const ProductHistoryScreen({super.key});

  @override
  State<ProductHistoryScreen> createState() => _ProductHistoryScreenState();
}

class _ProductHistoryScreenState extends State<ProductHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      double val = price / 1000000000;
      return "Rp ${val.toStringAsFixed(1).replaceAll('.0', '')}M";
    } else if (price >= 1000000) {
      double val = price / 1000000;
      return "Rp ${val.toStringAsFixed(1).replaceAll('.0', '')}jt";
    } else {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(price);
    }
  }

  void _confirmDelete(String productId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text("Hapus Produk?"),
        content: Text("Anda yakin ingin menghapus '$productName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              await provider.deleteProduct(productId);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToEditScreen(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme handling
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.salmon : AppColors.deepTeal;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Database")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: accentColor),
                hintText: "Cari nama produk...",
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada produk."));
                }

                var docs = snapshot.data!.docs;
                var filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("Produk tidak ditemukan."));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    Product product = Product.fromFirestore(
                      data,
                      filteredDocs[index].id,
                    );

                    ImageProvider? imgProvider;
                    if (product.images.isNotEmpty) {
                      try {
                        String cleanBase64 = product.images.first
                            .split(',')
                            .last;
                        cleanBase64 = cleanBase64.replaceAll(
                          RegExp(r'\s+'),
                          '',
                        );
                        imgProvider = MemoryImage(base64Decode(cleanBase64));
                      } catch (e) {
                        imgProvider = null;
                      }
                    }

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                            image: imgProvider != null
                                ? DecorationImage(
                                    image: imgProvider,
                                    fit: BoxFit.contain,
                                  )
                                : null,
                          ),
                          child: imgProvider == null
                              ? const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        title: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${product.brand}\n${_formatPrice(product.priceOnlineMin)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.deepTeal,
                              ),
                              onPressed: () => _navigateToEditScreen(product),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.salmon,
                              ),
                              onPressed: () =>
                                  _confirmDelete(product.id, product.name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
