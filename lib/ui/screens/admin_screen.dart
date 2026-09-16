import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../data/models/skincare_model.dart';
import '../../providers/app_provider.dart';
import 'login_screen.dart';
import 'product_history_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // ==========================================
  // 1. STATE & CONTROLLERS
  // ==========================================

  // --- KONTROLER INPUT MANUAL ---
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _onlineMinCtrl = TextEditingController();
  final _onlineMaxCtrl = TextEditingController();
  final _offlineMinCtrl = TextEditingController();
  final _offlineMaxCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ingredCtrl = TextEditingController();
  final _minAgeCtrl = TextEditingController();
  final _maxAgeCtrl = TextEditingController();
  final _variationNameCtrl = TextEditingController();

  // --- DROPDOWN OPTIONS ---
  final List<String> _skinOptions = [
    "Normal",
    "Kering",
    "Berminyak",
    "Berjerawat",
  ];
  String _skinType = 'Normal';

  final List<String> _genderOptions = ["Unisex", "Pria", "Wanita"];
  String _targetGender = 'Unisex';

  final List<String> _categoryOptions = [
    "Facial Wash",
    "Toner",
    "Serum",
    "Moisturizer",
    "Sunscreen",
    "Masker",
    "Exfoliator",
    "Lainnya",
  ];
  String _selectedCategory = 'Facial Wash';

  // --- State Validasi Gambar ---
  bool _showImageError = false;

  // Data Manual
  List<File> _selectedImages = [];
  List<String> _base64Images = [];
  List<Map<String, dynamic>> _tempVariations = [];
  int _selectedVariationImageIndex = 0;

  // --- STATE PREVIEW CSV ---
  bool _isPreviewMode = false;
  List<Product> _csvPreviewList = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _onlineMinCtrl.dispose();
    _onlineMaxCtrl.dispose();
    _offlineMinCtrl.dispose();
    _offlineMaxCtrl.dispose();
    _descCtrl.dispose();
    _ingredCtrl.dispose();
    _minAgeCtrl.dispose();
    _maxAgeCtrl.dispose();
    _variationNameCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // [HELPER] FORMATTER & PARSER
  // ==========================================

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    String str = value.toString();
    str = str.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(str) ?? 0.0;
  }

  String _formatPriceForPreview(double price) {
    if (price >= 1000000000) {
      return "Rp ${(price / 1000000000).toStringAsFixed(1).replaceAll('.0', '')}M";
    } else if (price >= 1000000) {
      return "Rp ${(price / 1000000).toStringAsFixed(1).replaceAll('.0', '')}jt";
    } else {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(price);
    }
  }

  // ==========================================
  // BAGIAN 2: LOGIKA IMPORT CSV & PREVIEW
  // ==========================================

  bool _isProductComplete(Product p) {
    return p.name.isNotEmpty &&
        p.brand.isNotEmpty &&
        p.priceOnlineMin > 0 &&
        p.images.isNotEmpty;
  }

  void _removeItemFromPreview(int index) {
    setState(() {
      _csvPreviewList.removeAt(index);
      if (_csvPreviewList.isEmpty) {
        _isPreviewMode = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Semua data dihapus. Kembali ke menu utama."),
          ),
        );
      }
    });
  }

  Future<void> _readCSVForPreview() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final fileContent = await file.readAsString();

        String delimiter = ',';
        if (fileContent.contains(';') &&
            fileContent.split(';').length > fileContent.split(',').length) {
          delimiter = ';';
        }

        final fields = CsvToListConverter(
          fieldDelimiter: delimiter,
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(fileContent);

        if (fields.isEmpty || fields.length < 2) {
          _showPopup("File CSV kosong atau format salah.", isError: true);
          return;
        }

        Map<String, Product> productMap = {};

        for (int i = 1; i < fields.length; i++) {
          try {
            List<dynamic> row = fields[i];
            if (row.length < 13) continue;

            String name = row[0].toString().trim();
            String brand = row[1].toString().trim();
            String key = "$name-$brand".toLowerCase();

            String variationName = "";
            if (row.length > 13) {
              variationName = row[13].toString().trim();
            }
            if (variationName.isEmpty) variationName = "Varian ${i}";

            if (productMap.containsKey(key)) {
              Product existing = productMap[key]!;
              List<Variation> updatedVars = List.from(existing.variations);
              updatedVars.add(Variation(name: variationName, imageIndex: 0));

              productMap[key] = Product(
                id: existing.id,
                name: existing.name,
                brand: existing.brand,
                category: existing.category,
                priceOnlineMin: existing.priceOnlineMin,
                priceOnlineMax: existing.priceOnlineMax,
                priceOfflineMin: existing.priceOfflineMin,
                priceOfflineMax: existing.priceOfflineMax,
                description: existing.description,
                ingredients: existing.ingredients,
                skinType: existing.skinType,
                targetGender: existing.targetGender,
                minAge: existing.minAge,
                maxAge: existing.maxAge,
                imageAsset: existing.imageAsset,
                images: existing.images,
                matchPercent: 0,
                variations: updatedVars,
              );
            } else {
              List<Variation> initVars = [];
              if (row.length > 13 && row[13].toString().trim().isNotEmpty) {
                initVars.add(
                  Variation(name: row[13].toString().trim(), imageIndex: 0),
                );
              }

              final newProduct = Product(
                id: const Uuid().v4(),
                name: name,
                brand: brand,
                category: row[2].toString(),
                priceOnlineMin: _parsePrice(row[3]),
                priceOnlineMax: _parsePrice(row[4]),
                priceOfflineMin: _parsePrice(row[5]),
                priceOfflineMax: _parsePrice(row[6]),
                description: row[7].toString(),
                ingredients: row[8].toString(),
                skinType: row[9].toString(),
                targetGender: row[10].toString(),
                minAge: int.tryParse(row[11].toString()) ?? 12,
                maxAge: int.tryParse(row[12].toString()) ?? 60,
                imageAsset: "",
                images: [],
                matchPercent: 0,
                variations: initVars,
              );
              productMap[key] = newProduct;
            }
          } catch (e) {
            debugPrint("Skip baris $i: $e");
          }
        }

        setState(() {
          _csvPreviewList = productMap.values.toList();
          _isPreviewMode = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Berhasil membaca ${_csvPreviewList.length} Produk (Grouping aktif).",
            ),
          ),
        );
      }
    } catch (e) {
      _showPopup("Gagal Membaca CSV: $e", isError: true);
    }
  }

  Future<void> _pickImageForPreviewItem(int index) async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 50,
        maxWidth: 800,
      );

      if (images.isNotEmpty) {
        List<String> base64List = [];
        for (var img in images) {
          File imgFile = File(img.path);
          List<int> bytes = await imgFile.readAsBytes();
          base64List.add("data:image/jpeg;base64,${base64Encode(bytes)}");
        }

        setState(() {
          Product old = _csvPreviewList[index];
          List<Variation> fixedVars = [];
          for (var v in old.variations) {
            int safeIndex = (v.imageIndex < base64List.length)
                ? v.imageIndex
                : 0;
            fixedVars.add(Variation(name: v.name, imageIndex: safeIndex));
          }

          _csvPreviewList[index] = Product(
            id: old.id,
            name: old.name,
            brand: old.brand,
            category: old.category,
            priceOnlineMin: old.priceOnlineMin,
            priceOnlineMax: old.priceOnlineMax,
            priceOfflineMin: old.priceOfflineMin,
            priceOfflineMax: old.priceOfflineMax,
            description: old.description,
            ingredients: old.ingredients,
            skinType: old.skinType,
            targetGender: old.targetGender,
            minAge: old.minAge,
            maxAge: old.maxAge,
            matchPercent: 0,
            variations: fixedVars,
            imageAsset: base64List.first,
            images: base64List,
          );
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil gambar: $e");
    }
  }

  // --- DIALOG TAMBAH VARIASI (PREVIEW) ---
  void _showAddVariationDialogPreview(int productIndex) {
    _variationNameCtrl.clear();
    int tempImageIndex = 0;
    Product prod = _csvPreviewList[productIndex];

    if (prod.images.isEmpty) {
      _showPopup("Upload gambar produk terlebih dahulu!", isError: true);
      return;
    }

    // [FIX] Tidak pakai variabel isDark. Gunakan logic langsung untuk accentColor
    final accentColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.salmon
        : AppColors.deepTeal;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text("Tambah Variasi (Preview)"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _variationNameCtrl,
                    decoration: const InputDecoration(labelText: "Nama Varian"),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Pilih Gambar:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    width: double.maxFinite,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: prod.images.length,
                      itemBuilder: (context, idx) {
                        final isSelected = tempImageIndex == idx;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => tempImageIndex = idx),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: isSelected
                                  ? Border.all(color: accentColor, width: 3)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.memory(
                              base64Decode(prod.images[idx].split(',').last),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Batal", style: TextStyle(color: accentColor)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_variationNameCtrl.text.isNotEmpty) {
                      setState(() {
                        Product current = _csvPreviewList[productIndex];
                        List<Variation> newVars = List.from(current.variations);
                        newVars.add(
                          Variation(
                            name: _variationNameCtrl.text,
                            imageIndex: tempImageIndex,
                          ),
                        );

                        _csvPreviewList[productIndex] = Product(
                          id: current.id,
                          name: current.name,
                          brand: current.brand,
                          category: current.category,
                          priceOnlineMin: current.priceOnlineMin,
                          priceOnlineMax: current.priceOnlineMax,
                          priceOfflineMin: current.priceOfflineMin,
                          priceOfflineMax: current.priceOfflineMax,
                          description: current.description,
                          ingredients: current.ingredients,
                          skinType: current.skinType,
                          targetGender: current.targetGender,
                          minAge: current.minAge,
                          maxAge: current.maxAge,
                          imageAsset: current.imageAsset,
                          images: current.images,
                          matchPercent: 0,
                          variations: newVars,
                        );
                      });
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                      _showPreviewDetailDialog(productIndex);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DIALOG DETAIL PREVIEW (DENGAN CAROUSEL) ---
  void _showPreviewDetailDialog(int index) {
    // [FIX] Tidak pakai variabel isDark.
    final accentColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.salmon
        : AppColors.deepTeal;
    int currentCarouselIndex = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Product currentProd = _csvPreviewList[index];
            bool hasImage = currentProd.images.isNotEmpty;

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(16),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Review Detail Produk",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (hasImage)
                      Column(
                        children: [
                          SizedBox(
                            height: 200,
                            width: double.maxFinite,
                            child: PageView.builder(
                              itemCount: currentProd.images.length,
                              onPageChanged: (page) => setStateDialog(
                                () => currentCarouselIndex = page,
                              ),
                              itemBuilder: (context, imgIdx) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickImageForPreviewItem(index);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: MemoryImage(
                                          base64Decode(
                                            currentProd.images[imgIdx]
                                                .split(',')
                                                .last,
                                          ),
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                      color: Colors.black12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(currentProd.images.length, (
                              i,
                            ) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: currentCarouselIndex == i ? 12 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: currentCarouselIndex == i
                                      ? accentColor
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Gambar ke-${currentCarouselIndex + 1} dari ${currentProd.images.length}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _pickImageForPreviewItem(index);
                        },
                        child: const Text("Upload Foto"),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      currentProd.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text("${currentProd.brand} • ${currentProd.category}"),
                    const SizedBox(height: 4),
                    Text(
                      _formatPriceForPreview(currentProd.priceOnlineMin),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.withOpacity(0.3)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Kelola Variasi",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _showAddVariationDialogPreview(index);
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text("Tambah"),
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                          ),
                        ),
                      ],
                    ),

                    if (currentProd.variations.isEmpty)
                      const Text(
                        "Belum ada variasi.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(currentProd.variations.length, (
                          vIdx,
                        ) {
                          final v = currentProd.variations[vIdx];
                          return Chip(
                            label: Text(
                              v.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            // [FIX] Cek theme langsung di sini
                            avatar: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              child: Text(
                                "${v.imageIndex + 1}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            backgroundColor: Theme.of(context).cardColor,
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            onDeleted: () {
                              setState(() {
                                List<Variation> newVars = List.from(
                                  currentProd.variations,
                                );
                                newVars.removeAt(vIdx);

                                _csvPreviewList[index] = Product(
                                  id: currentProd.id,
                                  name: currentProd.name,
                                  brand: currentProd.brand,
                                  category: currentProd.category,
                                  priceOnlineMin: currentProd.priceOnlineMin,
                                  priceOnlineMax: currentProd.priceOnlineMax,
                                  priceOfflineMin: currentProd.priceOfflineMin,
                                  priceOfflineMax: currentProd.priceOfflineMax,
                                  description: currentProd.description,
                                  ingredients: currentProd.ingredients,
                                  skinType: currentProd.skinType,
                                  targetGender: currentProd.targetGender,
                                  minAge: currentProd.minAge,
                                  maxAge: currentProd.maxAge,
                                  imageAsset: currentProd.imageAsset,
                                  images: currentProd.images,
                                  matchPercent: 0,
                                  variations: newVars,
                                );
                              });
                              setStateDialog(() {});
                            },
                          );
                        }),
                      ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Simpan & Tutup"),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleUploadButton() async {
    if (_csvPreviewList.isEmpty) return;

    int invalidIndex = _csvPreviewList.indexWhere(
      (p) => !_isProductComplete(p),
    );

    if (invalidIndex != -1) {
      Product invalidProd = _csvPreviewList[invalidIndex];
      _showPopup(
        "Gagal Upload!\n\nProduk '${invalidProd.name}' belum lengkap (Wajib ada Gambar).\n\nSilakan cek ulang data yang bertanda ⚠️.",
        isError: true,
      );
      return;
    }

    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: const Text("Validasi Akhir"),
            content: Text(
              "Anda akan mengupload ${_csvPreviewList.length} produk ke Database.\n\nPastikan gambar dan nama produk sudah sesuai.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "Cek Ulang",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  "Yakin, Upload",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    int successCount = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    for (var product in _csvPreviewList) {
      await provider.addProduct(product);
      successCount++;
    }

    if (!mounted) return;
    Navigator.pop(context);

    _showPopup(
      "Sukses! $successCount produk berhasil disimpan.",
      isSuccess: true,
    );

    setState(() {
      _csvPreviewList.clear();
      _isPreviewMode = false;
    });
  }

  // ==========================================
  // BAGIAN 2: LOGIKA SINGLE INPUT (MANUAL)
  // ==========================================

  Future<void> _pickImagesManual() async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedList = await picker.pickMultiImage(
        imageQuality: 50,
        maxWidth: 800,
      );
      if (pickedList.isNotEmpty) {
        List<File> tempFiles = [];
        List<String> tempBase64 = [];
        for (var xFile in pickedList) {
          File img = File(xFile.path);
          int sizeInBytes = await img.length();
          if (sizeInBytes / (1024 * 1024) > 1.0) continue;
          List<int> bytes = await img.readAsBytes();
          tempFiles.add(img);
          tempBase64.add("data:image/jpeg;base64,${base64Encode(bytes)}");
        }
        setState(() {
          _selectedImages.addAll(tempFiles);
          _base64Images.addAll(tempBase64);
          _showImageError =
              false; // [FIX] Variabel ini digunakan untuk reset error
        });
      }
    } catch (e) {
      /* Error handling */
    }
  }

  void _removeImageManual(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _base64Images.removeAt(index);
      _tempVariations.removeWhere((v) => v['imageIndex'] == index);
      for (var v in _tempVariations) {
        if (v['imageIndex'] > index) v['imageIndex'] = v['imageIndex'] - 1;
      }
    });
  }

  void _showAddVariationDialog() {
    if (_selectedImages.isEmpty) {
      // [FIX] Validasi merah menggunakan _showImageError
      setState(() => _showImageError = true);
      _showPopup(
        "Upload gambar produk dulu sebelum buat variasi!",
        isError: true,
      );
      return;
    }
    _variationNameCtrl.clear();
    _selectedVariationImageIndex = 0;

    // [FIX] Tidak pakai isDark
    final accentColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.salmon
        : AppColors.deepTeal;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text("Tambah Variasi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _variationNameCtrl,
                decoration: const InputDecoration(labelText: "Nama Varian"),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                width: double.maxFinite,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (c, i) => GestureDetector(
                    onTap: () => setSt(() => _selectedVariationImageIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: _selectedVariationImageIndex == i
                            ? Border.all(color: accentColor, width: 3)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.file(
                        _selectedImages[i],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_variationNameCtrl.text.isNotEmpty) {
                  _addVariation(
                    _variationNameCtrl.text,
                    _selectedVariationImageIndex,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _addVariation(String name, int imgIndex) {
    setState(() => _tempVariations.add({'name': name, 'imageIndex': imgIndex}));
  }

  void _removeVariation(int index) {
    setState(() => _tempVariations.removeAt(index));
  }

  Future<void> _submitProductManual() async {
    // 1. VALIDASI GAMBAR (Merah) - [FIX] Set state _showImageError
    if (_base64Images.isEmpty) {
      setState(() => _showImageError = true);
    } else {
      setState(() => _showImageError = false);
    }

    // 2. VALIDASI DATA LENGKAP (Popup)
    if (_base64Images.isEmpty ||
        _nameCtrl.text.isEmpty ||
        _brandCtrl.text.isEmpty ||
        _onlineMinCtrl.text.isEmpty ||
        _descCtrl.text.isEmpty ||
        _minAgeCtrl.text.isEmpty ||
        _maxAgeCtrl.text.isEmpty) {
      _showPopup(
        "Mohon lengkapi semua data dan upload minimal 1 foto!",
        isError: true,
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    double onMin =
        double.tryParse(_onlineMinCtrl.text.replaceAll('.', '')) ?? 0;
    double onMax =
        double.tryParse(_onlineMaxCtrl.text.replaceAll('.', '')) ?? onMin;
    double offMin =
        double.tryParse(_offlineMinCtrl.text.replaceAll('.', '')) ?? 0;
    double offMax =
        double.tryParse(_offlineMaxCtrl.text.replaceAll('.', '')) ?? offMin;
    int minAge = int.tryParse(_minAgeCtrl.text) ?? 0;
    int maxAge = int.tryParse(_maxAgeCtrl.text) ?? 99;

    List<Variation> vars = _tempVariations
        .map((v) => Variation(name: v['name'], imageIndex: v['imageIndex']))
        .toList();

    final prod = Product(
      id: const Uuid().v4(),
      name: _nameCtrl.text,
      brand: _brandCtrl.text,
      category: _selectedCategory, // Use Dropdown Value
      priceOnlineMin: onMin,
      priceOnlineMax: onMax,
      priceOfflineMin: offMin,
      priceOfflineMax: offMax,
      imageAsset: _base64Images.first,
      images: _base64Images,
      description: _descCtrl.text,
      ingredients: _ingredCtrl.text,
      skinType: _skinType,
      targetGender: _targetGender,
      minAge: minAge,
      maxAge: maxAge,
      matchPercent: 0,
      variations: vars,
    );

    await provider.addProduct(prod);
    if (mounted) {
      _showPopup("Produk Manual Berhasil Disimpan!", isSuccess: true);
      _resetFormManual();
    }
  }

  void _resetFormManual() {
    _nameCtrl.clear();
    _brandCtrl.clear();
    _onlineMinCtrl.clear();
    _onlineMaxCtrl.clear();
    _offlineMinCtrl.clear();
    _offlineMaxCtrl.clear();
    _descCtrl.clear();
    _ingredCtrl.clear();
    _minAgeCtrl.clear();
    _maxAgeCtrl.clear();
    setState(() {
      _selectedImages.clear();
      _base64Images.clear();
      _tempVariations.clear();
      _showImageError = false; // Reset error state
      _skinType = "Normal";
      _targetGender = "Unisex";
      _selectedCategory = "Facial Wash";
    });
  }

  void _showPopup(String msg, {bool isError = false, bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.cancel_outlined : Icons.check_circle_rounded,
              color: isError ? Colors.redAccent : Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BAGIAN 3: BUILD UI (SWAP VIEW)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (_isPreviewMode) {
      return _buildPreviewUI();
    }
    return _buildInputFormUI();
  }

  // --- TAMPILAN PREVIEW ---
  Widget _buildPreviewUI() {
    final cardColor = Theme.of(context).cardColor;

    int total = _csvPreviewList.length;
    int readyCount = _csvPreviewList.where((p) => _isProductComplete(p)).length;
    bool isAllReady = readyCount == total && total > 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Preview Import CSV", style: TextStyle(fontSize: 18)),
            Text(
              "Siap Upload: $readyCount dari $total Produk",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: isAllReady ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _isPreviewMode = false;
            _csvPreviewList.clear();
          }),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: isAllReady
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  isAllReady ? Icons.check_circle : Icons.info_outline,
                  color: isAllReady ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAllReady
                        ? "Semua data lengkap! Siap untuk diupload."
                        : "Harap lengkapi Foto Produk. Hapus semua data untuk kembali.",
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _csvPreviewList.length,
              itemBuilder: (context, index) {
                final prod = _csvPreviewList[index];
                final isComplete = _isProductComplete(prod);
                return Card(
                  color: isComplete
                      ? cardColor
                      : Colors.amber.withOpacity(0.05),
                  elevation: isComplete ? 1 : 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isComplete
                          ? Colors.transparent
                          : Colors.orange.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    onTap: () => _showPreviewDetailDialog(index),
                    leading: GestureDetector(
                      onTap: () => _pickImageForPreviewItem(index),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: prod.images.isNotEmpty
                                ? Colors.green
                                : Colors.grey,
                          ),
                          image: prod.images.isNotEmpty
                              ? DecorationImage(
                                  image: MemoryImage(
                                    base64Decode(
                                      prod.images.first.split(',').last,
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: prod.images.isEmpty
                            ? const Icon(Icons.add_a_photo, color: Colors.grey)
                            : null,
                      ),
                    ),
                    title: Text(prod.name),
                    subtitle: Text(
                      "${prod.brand} • ${_formatPriceForPreview(prod.priceOnlineMin)}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItemFromPreview(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isPreviewMode = false;
                    _csvPreviewList.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "BATAL",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAllReady ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _handleUploadButton,
                child: Text(
                  isAllReady
                      ? "UPLOAD SEMUA"
                      : "LENGKAPI (${readyCount}/${total})",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI INPUT MANUAL ---
  Widget _buildInputFormUI() {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final accentColor = isDark ? AppColors.salmon : AppColors.deepTeal;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    final containerColor = isDark
        ? AppColors.surfaceDark
        : AppColors.deepTeal.withOpacity(0.05);

    // --- FIX FONT DROPDOWN ---
    final inputTextStyle = TextStyle(
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.normal,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Dashboard Admin",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              provider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // MENU HISTORY
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductHistoryScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mustard, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.history_edu, color: AppColors.mustard, size: 28),
                  SizedBox(width: 16),
                  Text(
                    "Kelola Database & Riwayat",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // CSV UPLOAD
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  "Upload CSV",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _readCSVForPreview,
                  icon: const Icon(Icons.file_copy),
                  label: const Text("PILIH FILE CSV"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),
          Text(
            "Input Manual",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),

          // --- FOTO ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImagesManual,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: accentColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: accentColor),
                        Text(
                          "Tambah",
                          style: TextStyle(fontSize: 10, color: accentColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ...List.generate(
                  _selectedImages.length,
                  (idx) => Stack(
                    children: [
                      Image.file(
                        _selectedImages[idx],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeImageManual(idx),
                          child: const Icon(Icons.cancel, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // [FIX] TEKS MERAH: Menggunakan variabel _showImageError (DIGUNAKAN DISINI)
          if (_showImageError && _base64Images.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0, left: 4.0),
              child: Text(
                "* Wajib upload minimal 1 foto produk",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameCtrl,
            label: "Nama Produk",
            context: context,
          ),
          const SizedBox(height: 10),

          // [DROPDOWN KATEGORI + BRAND]
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _brandCtrl,
                  label: "Brand",
                  context: context,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  style: inputTextStyle,
                  decoration: InputDecoration(
                    labelText: "Kategori",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _categoryOptions
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, style: inputTextStyle),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _onlineMinCtrl,
                  label: "Harga Online Min",
                  isCurrency: true,
                  context: context,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _onlineMaxCtrl,
                  label: "Harga Online Max",
                  isCurrency: true,
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _offlineMinCtrl,
                  label: "Harga Offline Min",
                  isCurrency: true,
                  context: context,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _offlineMaxCtrl,
                  label: "Harga Offline Max",
                  isCurrency: true,
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _descCtrl,
            label: "Deskripsi",
            maxLines: 3,
            context: context,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _ingredCtrl,
            label: "Ingredients",
            maxLines: 3,
            context: context,
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _minAgeCtrl,
                  label: "Min Usia",
                  isNumber: true,
                  context: context,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _maxAgeCtrl,
                  label: "Max Usia",
                  isNumber: true,
                  context: context,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          // [LAYOUT BARU 2:1]
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _skinType,
                  isExpanded: true,
                  style: inputTextStyle,
                  decoration: InputDecoration(
                    labelText: "Tipe Kulit",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _skinOptions
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: inputTextStyle),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _skinType = val!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _targetGender,
                  isExpanded: true,
                  style: inputTextStyle,
                  decoration: InputDecoration(
                    labelText: "Gender",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _genderOptions
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: inputTextStyle),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _targetGender = val!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Variasi",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddVariationDialog,
                icon: Icon(Icons.add_circle_outline, color: accentColor),
                label: Text("Tambah", style: TextStyle(color: accentColor)),
              ),
            ],
          ),
          if (_tempVariations.isEmpty)
            const Text(
              "Belum ada variasi...",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          Wrap(
            spacing: 8,
            children: List.generate(
              _tempVariations.length,
              (index) => Chip(
                label: Text(_tempVariations[index]['name']),
                avatar: CircleAvatar(
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                  child: Text("${_tempVariations[index]['imageIndex'] + 1}"),
                ),
                backgroundColor: cardColor,
                onDeleted: () => _removeVariation(index),
              ),
            ),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _submitProductManual,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "SIMPAN MANUAL",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: () {
                _resetFormManual();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Formulir dibersihkan.")),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "BATAL",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
    bool isCurrency = false,
    int maxLines = 1,
    bool isNumber = false,
    int? maxLength,
  }) {
    List<TextInputFormatter> formatters = [];
    if (isCurrency) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      formatters.add(_CurrencyInputFormatter());
    }
    if (isNumber) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }
    if (maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(maxLength));
    }

    return TextField(
      controller: controller,
      keyboardType: (isCurrency || isNumber)
          ? TextInputType.number
          : TextInputType.text,
      maxLines: maxLines,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    if (n.text.isEmpty) return n;
    int val = int.parse(n.text);
    final fmt = NumberFormat.decimalPattern('id_ID');
    String newText = fmt.format(val);
    return n.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
