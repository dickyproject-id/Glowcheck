import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/models/skincare_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final int? matchPercent;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.matchPercent,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  int _selectedVariationIndex = 0;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- HELPER FORMATTER ---
  String _formatCompactCurrency(double value) {
    if (value >= 1000000000) {
      double result = value / 1000000000;
      return "Rp\u00A0${result.toStringAsFixed(1).replaceAll('.', ',')}M";
    } else if (value >= 1000000) {
      double result = value / 1000000;
      String str = result.toStringAsFixed(1).replaceAll('.', ',');
      if (str.endsWith(',0')) str = str.substring(0, str.length - 2);
      return "Rp\u00A0${str}jt";
    } else {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp\u00A0',
        decimalDigits: 0,
      ).format(value);
    }
  }

  String _formatPriceRange(double min, double max) {
    if (min == 0 && max == 0) return "-";
    if (min == max) return _formatCompactCurrency(min);
    return "${_formatCompactCurrency(min)} - ${_formatCompactCurrency(max)}";
  }

  // --- ZOOM IMAGE ---
  void _showFullScreenImage(BuildContext context, String imageSource) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: _buildImageContent(imageSource, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 10,
                right: 16,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(String source, {BoxFit fit = BoxFit.cover}) {
    if (source.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
      );
    }
    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.deepTeal.withOpacity(0.5),
            ),
          ),
        ),
        errorWidget: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    } else if (File(source).existsSync()) {
      return Image.file(File(source), fit: fit);
    } else {
      try {
        String cleanBase64 = source;
        if (source.contains(',')) cleanBase64 = source.split(',').last;
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        Uint8List bytes = base64Decode(cleanBase64);
        return Image.memory(bytes, fit: fit);
      } catch (e) {
        return Image.asset(
          source,
          fit: fit,
          errorBuilder: (_, __, ___) => const Icon(Icons.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final mutedTextColor = textColor.withOpacity(0.6);
    final borderColor = textColor.withOpacity(0.1);

    final primaryColor = isDark ? AppColors.salmon : AppColors.deepTeal;
    final highlightColor = isDark ? AppColors.brightYellow : AppColors.deepTeal;

    final Stream<DocumentSnapshot> productStream = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .snapshots();

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: productStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.deepTeal),
            );
          }

          if (snapshot.hasError || !snapshot.data!.exists) {
            return Scaffold(
              appBar: AppBar(
                elevation: 0,
                backgroundColor: scaffoldColor,
                iconTheme: IconThemeData(color: textColor),
              ),
              body: Center(
                child: Text(
                  "Produk tidak ditemukan.",
                  style: TextStyle(color: textColor),
                ),
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          Product product = Product.fromFirestore(data, snapshot.data!.id);

          final int displayMatch = widget.matchPercent ?? product.matchPercent;

          List<String> displayImages = [];
          if (product.images.isNotEmpty) displayImages.addAll(product.images);
          if (displayImages.isEmpty && product.imageAsset.isNotEmpty) {
            displayImages.add(product.imageAsset);
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // --- HEADER GAMBAR ---
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 450,
                    backgroundColor: scaffoldColor,
                    elevation: 0,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: displayImages.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                                for (
                                  int i = 0;
                                  i < product.variations.length;
                                  i++
                                ) {
                                  if (product.variations[i].imageIndex ==
                                      index) {
                                    _selectedVariationIndex = i;
                                    break;
                                  }
                                }
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _showFullScreenImage(
                                  context,
                                  displayImages[index],
                                ),
                                child: KeepAliveImageWrapper(
                                  child: _buildImageContent(
                                    displayImages[index],
                                  ),
                                ),
                              );
                            },
                          ),
                          if (displayImages.length > 1)
                            Positioned(
                              bottom: 60,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(displayImages.length, (
                                  index,
                                ) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: _currentImageIndex == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentImageIndex == index
                                          ? primaryColor
                                          : Colors.white70,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // --- BOX DETAIL ---
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0.0, -40.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(40),
                          ),
                          boxShadow: const [], // NO SHADOW (CLEAN LOOK)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. GARIS INDIKATOR
                            const SizedBox(height: 12),
                            Center(
                              child: Container(
                                width: 50,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            // PADDING UTAMA
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                42,
                                24,
                                100,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 2. BRAND & KATEGORI
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          product.category.isNotEmpty
                                              ? product.category
                                              : "General",
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (product.brand.isNotEmpty)
                                        Text(
                                          product.brand.toUpperCase(),
                                          style: TextStyle(
                                            color: mutedTextColor,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // 3. NAMA PRODUK
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // 4. HARGA
                                  Text(
                                    _formatPriceRange(
                                      product.priceOnlineMin,
                                      product.priceOnlineMax,
                                    ),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // 5. TABEL SPESIFIKASI
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: borderColor),
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey[50],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                          ),
                                          child: Text(
                                            "Spesifikasi Produk",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),

                                        if (displayMatch > 0)
                                          _buildTableRow(
                                            "Kecocokan",
                                            "$displayMatch% Cocok",
                                            isDark,
                                            borderColor,
                                            valueColor: highlightColor,
                                            isBoldValue: true,
                                          ),

                                        _buildTableRow(
                                          "Tipe Kulit",
                                          product.skinType,
                                          isDark,
                                          borderColor,
                                        ),
                                        _buildTableRow(
                                          "Gender",
                                          product.targetGender,
                                          isDark,
                                          borderColor,
                                        ),
                                        _buildTableRow(
                                          "Usia",
                                          "${product.minAge} - ${product.maxAge} Tahun",
                                          isDark,
                                          borderColor,
                                        ),

                                        if (product.priceOfflineMin > 0)
                                          _buildTableRow(
                                            "Harga Offline",
                                            _formatPriceRange(
                                              product.priceOfflineMin,
                                              product.priceOfflineMax,
                                            ),
                                            isDark,
                                            borderColor,
                                            isLast: true,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // 6. PILIHAN VARIASI
                                  if (product.variations.isNotEmpty) ...[
                                    Text(
                                      "Pilihan Variasi",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: List.generate(
                                        product.variations.length,
                                        (index) {
                                          final variant =
                                              product.variations[index];
                                          final isSelected =
                                              _selectedVariationIndex == index;
                                          return ChoiceChip(
                                            label: Text(variant.name),
                                            selected: isSelected,
                                            selectedColor: primaryColor
                                                .withOpacity(0.2),
                                            backgroundColor: scaffoldColor,
                                            labelStyle: TextStyle(
                                              color: isSelected
                                                  ? primaryColor
                                                  : mutedTextColor,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              side: BorderSide(
                                                color: isSelected
                                                    ? primaryColor
                                                    : Colors.transparent,
                                              ),
                                            ),
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _selectedVariationIndex =
                                                      index;
                                                  if (variant.imageIndex >= 0 &&
                                                      variant.imageIndex <
                                                          displayImages
                                                              .length) {
                                                    _currentImageIndex =
                                                        variant.imageIndex;
                                                    _pageController
                                                        .animateToPage(
                                                          variant.imageIndex,
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    600,
                                                              ),
                                                          curve:
                                                              Curves.easeInOut,
                                                        );
                                                  }
                                                });
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // 7. DESKRIPSI
                                  Text(
                                    "Deskripsi",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildExpandableText(
                                    product.description.isEmpty
                                        ? "Tidak ada deskripsi."
                                        : product.description,
                                    textColor,
                                    primaryColor,
                                  ),

                                  const SizedBox(height: 30),

                                  // 8. KANDUNGAN UTAMA (UPDATED STYLE)
                                  Text(
                                    "Kandungan Utama",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      // [NEW DESIGN] Soft colored background + Border
                                      color: primaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: primaryColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Ikon Medis/Sains
                                        Icon(
                                          Icons.science_outlined,
                                          color: primaryColor,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            product.ingredients.isEmpty
                                                ? "-"
                                                : product.ingredients,
                                            style: TextStyle(
                                              color: textColor.withOpacity(
                                                0.8,
                                              ), // Teks sedikit lebih gelap agar terbaca
                                              height: 1.6,
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // BUTTON BELI
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SizedBox(
                    height: 55,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Fitur Beli Segera Hadir!"),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "BELI SEKARANG",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildTableRow(
    String label,
    String value,
    bool isDark,
    Color borderColor, {
    bool isLast = false,
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableText(String text, Color textColor, Color accentColor) {
    const int truncateLength = 150;
    bool isLongText = text.length > truncateLength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            height: 1.6,
            fontSize: 15,
          ),
          maxLines: _isDescriptionExpanded ? null : 3,
          overflow: _isDescriptionExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        if (isLongText)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: GestureDetector(
              onTap: () => setState(
                () => _isDescriptionExpanded = !_isDescriptionExpanded,
              ),
              child: Text(
                _isDescriptionExpanded
                    ? "Lihat Lebih Sedikit"
                    : "Lihat Selengkapnya",
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class KeepAliveImageWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveImageWrapper({super.key, required this.child});
  @override
  _KeepAliveImageWrapperState createState() => _KeepAliveImageWrapperState();
}

class _KeepAliveImageWrapperState extends State<KeepAliveImageWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
