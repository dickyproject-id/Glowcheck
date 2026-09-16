import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models/skincare_model.dart';
import '../../providers/app_provider.dart';
import 'home_screen.dart';
import 'product_detail_screen.dart';

class ResultScreen extends StatelessWidget {
  final bool isHistoryView;

  const ResultScreen({super.key, this.isHistoryView = false});

  // --- FULL SCREEN IMAGE HELPER ---
  void _showFullScreenImage(BuildContext context, String imageSource) {
    final imageProvider = _getImageProvider(imageSource);
    if (imageProvider == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                alignment: Alignment.centerRight,
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
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image(image: imageProvider, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- IMAGE PROVIDER HELPER ---
  ImageProvider? _getImageProvider(String path) {
    if (path.startsWith('base64,')) {
      try {
        String cleanBase64 = path.split(',').last;
        Uint8List bytes = base64Decode(cleanBase64);
        return MemoryImage(bytes);
      } catch (e) {
        return null;
      }
    } else if (path.isNotEmpty && File(path).existsSync()) {
      return FileImage(File(path));
    }
    return null;
  }

  // --- FACE COUNT HELPER ---
  Future<int> _countFacesInImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: false,
      enableClassification: false,
    );
    final faceDetector = FaceDetector(options: options);
    try {
      final List<Face> faces = await faceDetector.processImage(inputImage);
      return faces.length;
    } catch (e) {
      return 0;
    } finally {
      faceDetector.close();
    }
  }

  // --- RESCAN OPTIONS ---
  void _showRescanOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.salmon : AppColors.deepTeal;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: iconColor),
                title: const Text('Ambil Foto (Kamera)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processNewScan(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: iconColor),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processNewScan(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processNewScan(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        final File imageFile = File(pickedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Memeriksa wajah..."),
            duration: Duration(milliseconds: 1000),
          ),
        );

        int faceCount = await _countFacesInImage(imageFile);
        if (!context.mounted) return;

        if (faceCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Wajah tidak terdeteksi!"),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        } else if (faceCount > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Terdeteksi >1 wajah!"),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final provider = Provider.of<AppProvider>(context, listen: false);
        await provider.analyzeImage(imageFile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mengambil gambar: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final result = provider.currentResult;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final primaryBtnColor = AppColors.deepTeal;
    final secondaryButtonColor = isDark ? AppColors.salmon : AppColors.deepTeal;
    const buttonTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.deepTeal),
        ),
      );
    }

    if (result == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: textColor),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text("Data Kosong", style: TextStyle(color: textColor)),
        ),
      );
    }

    final imageProvider = _getImageProvider(result.localImagePath);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Hasil Analisis",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO WAJAH
            Center(
              child: GestureDetector(
                onTap: () {
                  if (imageProvider != null) {
                    _showFullScreenImage(context, result.localImagePath);
                  }
                },
                child: Hero(
                  tag: 'face_image_${result.id}',
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      image: imageProvider != null
                          ? DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: imageProvider == null
                        ? const Center(
                            child: Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                          )
                        : Stack(
                            children: [
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CARD TIPE KULIT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Tipe Kulit Kamu",
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.skinType,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getSkinTypeColor(result.skinType),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // HEADER REKOMENDASI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Rekomendasi Produk",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (provider.recommendations.isNotEmpty)
                  Text(
                    "${provider.recommendations.length} item",
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // [FITUR BARU] 2 DROPDOWN BERDAMPINGAN (Kategori & Sortir)
            if (provider.availableCategories.isNotEmpty) ...[
              Row(
                children: [
                  // DROPDOWN KATEGORI
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.deepTeal.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.selectedCategory,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.filter_alt_outlined,
                            color: AppColors.deepTeal,
                            size: 20,
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: cardColor,
                          items: provider.availableCategories.map((
                            String category,
                          ) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null)
                              provider.filterByCategory(newValue);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // DROPDOWN SORTIR HARGA
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.deepTeal.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.currentSortOption,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.sort_rounded,
                            color: AppColors.deepTeal,
                            size: 20,
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: cardColor,
                          items:
                              [
                                'Paling Cocok',
                                'Harga Terendah',
                                'Harga Tertinggi',
                              ].map((String sort) {
                                return DropdownMenuItem<String>(
                                  value: sort,
                                  child: Text(
                                    sort,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null)
                              provider.sortProducts(newValue);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // GRID PRODUK
            if (provider.recommendations.isEmpty)
              _buildEmptyState(textColor, cardColor)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.recommendations.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final product = provider.recommendations[index];
                  return _buildProductCard(context, product);
                },
              ),

            const SizedBox(height: 30),

            // --- TOMBOL AKSI (SIMPAN & RESCAN) ---
            if (!isHistoryView) ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          await provider.saveHistoryToFirebase();
                          if (context.mounted &&
                              provider.errorMessage == null) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => AlertDialog(
                                backgroundColor: cardColor,
                                title: Text(
                                  "Berhasil",
                                  style: TextStyle(color: textColor),
                                ),
                                content: Text(
                                  "Hasil analisis berhasil disimpan ke riwayat!",
                                  style: TextStyle(color: textColor),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const HomeScreen(),
                                        ),
                                      );
                                      provider.resetAnalysis();
                                    },
                                    child: const Text(
                                      "OK",
                                      style: TextStyle(
                                        color: AppColors.deepTeal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.errorMessage ?? "Gagal Simpan",
                                ),
                              ),
                            );
                          }
                        },
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_alt, color: Colors.white),
                  label: Text(
                    provider.isLoading ? "Menyimpan..." : "SIMPAN KE RIWAYAT",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBtnColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () => _showRescanOptions(context),
                  icon: Icon(
                    Icons.center_focus_weak,
                    color: secondaryButtonColor,
                  ),
                  label: const Text("Scan Ulang Wajah"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondaryButtonColor,
                    side: BorderSide(color: secondaryButtonColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: buttonTextStyle,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceColor = isDark ? AppColors.salmon : AppColors.deepTeal;
    final matchColor = isDark ? AppColors.brightYellow : AppColors.deepTeal;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            productId: product.id,
            matchPercent: product.matchPercent,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildProductImage(product),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.isNotEmpty
                        ? product.category.toUpperCase()
                        : "GENERAL",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(product.priceOnlineMin),
                    style: TextStyle(
                      color: priceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: matchColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${product.matchPercent}% Cocok",
                      style: TextStyle(
                        fontSize: 10,
                        color: matchColor,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildProductImage(Product product) {
    String source = "";
    if (product.images.isNotEmpty) {
      source = product.images.first;
    } else if (product.imageAsset.isNotEmpty) {
      source = product.imageAsset;
    }

    if (source.isEmpty)
      return const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );

    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.deepTeal.withOpacity(0.5),
            ),
          ),
        ),
        errorWidget: (context, url, error) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else if (File(source).existsSync()) {
      return Image.file(
        File(source),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else {
      try {
        String cleanBase64 = source.contains(',')
            ? source.split(',').last
            : source;
        Uint8List bytes = base64Decode(
          cleanBase64.replaceAll(RegExp(r'\s+'), ''),
        );
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    }
  }

  Widget _buildEmptyState(Color? textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.softGrey,
            ),
            const SizedBox(height: 10),
            Text(
              "Tidak ada produk di kategori ini.",
              style: TextStyle(color: textColor?.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSkinTypeColor(String type) {
    if (type.contains('Jerawat')) return Colors.redAccent;
    if (type.contains('Minyak')) return Colors.orange;
    if (type.contains('Kering')) return Colors.blue;
    return AppColors.deepTeal;
  }
}
