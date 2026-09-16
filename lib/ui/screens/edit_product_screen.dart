import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/models/skincare_model.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLERS (Hanya untuk Text Input) ---
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  // Kategori pakai Dropdown
  late TextEditingController _onlineMinCtrl;
  late TextEditingController _onlineMaxCtrl;
  late TextEditingController _offlineMinCtrl;
  late TextEditingController _offlineMaxCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _ingredCtrl;
  late TextEditingController _minAgeCtrl;
  late TextEditingController _maxAgeCtrl;

  // --- STATE DATA (DROPDOWN) ---
  late String _skinType;
  late String _targetGender;
  late String _selectedCategory;

  // OPSI DROPDOWN (SAMA PERSIS DENGAN ADMIN SCREEN)
  final List<String> _skinOptions = [
    "Normal",
    "Kering",
    "Berminyak",
    "Berjerawat",
  ];
  final List<String> _genderOptions = ["Unisex", "Pria", "Wanita"];
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

  List<String> _images = []; // Base64 Strings
  List<Variation> _variations = [];

  bool _isLoading = false;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    // 1. Load Data Teks
    _nameCtrl = TextEditingController(text: p.name);
    _brandCtrl = TextEditingController(text: p.brand);

    _onlineMinCtrl = TextEditingController(
      text: p.priceOnlineMin.toInt().toString(),
    );
    _onlineMaxCtrl = TextEditingController(
      text: p.priceOnlineMax.toInt().toString(),
    );
    _offlineMinCtrl = TextEditingController(
      text: p.priceOfflineMin.toInt().toString(),
    );
    _offlineMaxCtrl = TextEditingController(
      text: p.priceOfflineMax.toInt().toString(),
    );

    _descCtrl = TextEditingController(text: p.description);
    _ingredCtrl = TextEditingController(text: p.ingredients);

    _minAgeCtrl = TextEditingController(text: p.minAge.toString());
    _maxAgeCtrl = TextEditingController(text: p.maxAge.toString());

    // 2. Load Dropdown (SAFE CHECK / ANTI CRASH)
    // Cek apakah data di database cocok dengan opsi dropdown. Jika tidak, pakai default.

    // Tipe Kulit
    if (_skinOptions.contains(p.skinType)) {
      _skinType = p.skinType;
    } else {
      _skinType = "Normal"; // Default jika data lama tidak valid
    }

    // Gender
    if (_genderOptions.contains(p.targetGender)) {
      _targetGender = p.targetGender;
    } else {
      _targetGender = "Unisex";
    }

    // Kategori
    if (_categoryOptions.contains(p.category)) {
      _selectedCategory = p.category;
    } else {
      _selectedCategory = "Facial Wash"; // Default aman
    }

    // 3. Load Images & Variations
    _images = List.from(p.images);
    _variations = List.from(p.variations);
  }

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
    super.dispose();
  }

  // --- LOGIKA GANTI GAMBAR ---
  Future<void> _pickNewImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedList = await picker.pickMultiImage(
        imageQuality: 50,
        maxWidth: 800,
      );

      if (pickedList.isNotEmpty) {
        List<String> newBase64List = [];
        for (var xFile in pickedList) {
          File img = File(xFile.path);
          List<int> bytes = await img.readAsBytes();
          newBase64List.add("data:image/jpeg;base64,${base64Encode(bytes)}");
        }

        setState(() {
          _images = newBase64List;
          _currentCarouselIndex = 0;

          // Reset index variasi agar tidak error (out of bounds)
          List<Variation> fixedVars = [];
          for (var v in _variations) {
            int safeIndex = (v.imageIndex < _images.length) ? v.imageIndex : 0;
            fixedVars.add(Variation(name: v.name, imageIndex: safeIndex));
          }
          _variations = fixedVars;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Gambar berhasil diganti (Klik Simpan untuk permanen).",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error pick images: $e");
    }
  }

  // --- LOGIKA TAMBAH VARIASI ---
  void _showAddVariationDialog() {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Upload gambar dulu sebelum tambah variasi!"),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    int selectedImgIdx = 0;

    // Warna Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.salmon : AppColors.deepTeal;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text("Tambah Variasi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
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
                      itemCount: _images.length,
                      itemBuilder: (context, idx) {
                        final isSelected = selectedImgIdx == idx;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedImgIdx = idx),
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
                              base64Decode(_images[idx].split(',').last),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      setState(() {
                        _variations.add(
                          Variation(
                            name: nameCtrl.text,
                            imageIndex: selectedImgIdx,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Tambah"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- SIMPAN PERUBAHAN KE FIREBASE ---
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal harus ada 1 gambar!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parsing Numeric
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

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({
            'name': _nameCtrl.text,
            'brand': _brandCtrl.text,
            'category': _selectedCategory, // Ambil dari Dropdown
            'priceOnlineMin': onMin,
            'priceOnlineMax': onMax,
            'priceOfflineMin': offMin,
            'priceOfflineMax': offMax,
            'description': _descCtrl.text,
            'ingredients': _ingredCtrl.text,
            'minAge': minAge,
            'maxAge': maxAge,
            'skinType': _skinType, // Ambil dari Dropdown
            'targetGender': _targetGender, // Ambil dari Dropdown
            'images': _images,
            'imageAsset': _images.first, // Update thumbnail utama
            'variations': _variations.map((v) => v.toMap()).toList(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produk berhasil diperbarui!")),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal update: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Setup Warna Tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.salmon : AppColors.deepTeal;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    // Style text agar Dropdown seragam dengan TextField
    final inputTextStyle = TextStyle(color: textColor, fontSize: 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Produk"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // --- SECTION 1: CAROUSEL GAMBAR ---
                  if (_images.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(
                          height: 250,
                          width: double.infinity,
                          child: PageView.builder(
                            itemCount: _images.length,
                            onPageChanged: (idx) =>
                                setState(() => _currentCarouselIndex = idx),
                            itemBuilder: (ctx, index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: MemoryImage(
                                      base64Decode(
                                        _images[index].split(',').last,
                                      ),
                                    ),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Indikator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_images.length, (idx) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentCarouselIndex == idx ? 12 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentCarouselIndex == idx
                                    ? accentColor
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickNewImages,
                      icon: Icon(Icons.camera_alt, color: accentColor),
                      label: Text(
                        "Ganti Foto (Pilih Ulang)",
                        style: TextStyle(color: accentColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Informasi Dasar",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _nameCtrl,
                    label: "Nama Produk",
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                  ),
                  const SizedBox(height: 12),

                  // [DROPDOWN KATEGORI & BRAND]
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _brandCtrl,
                          label: "Brand",
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t, style: inputTextStyle),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val!),
                        ),
                      ),
                    ],
                  ),

                  // --- MANAJEMEN VARIASI ---
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Variasi Produk",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddVariationDialog,
                        icon: Icon(Icons.add_circle, color: accentColor),
                        label: Text(
                          "Tambah",
                          style: TextStyle(color: accentColor),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_variations.length, (index) {
                      final v = _variations[index];
                      return Chip(
                        label: Text(v.name),
                        avatar: CircleAvatar(
                          backgroundColor: isDark
                              ? Colors.grey[700]
                              : Colors.grey[200],
                          child: Text(
                            "${v.imageIndex + 1}",
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        backgroundColor: cardColor,
                        onDeleted: () {
                          setState(() {
                            _variations.removeAt(index);
                          });
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Harga (Rupiah)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _onlineMinCtrl,
                          label: "Online Min",
                          isCurrency: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _onlineMaxCtrl,
                          label: "Online Max",
                          isCurrency: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _offlineMinCtrl,
                          label: "Offline Min",
                          isCurrency: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _offlineMaxCtrl,
                          label: "Offline Max",
                          isCurrency: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Detail Produk",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _descCtrl,
                    label: "Deskripsi",
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _ingredCtrl,
                    label: "Ingredients",
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Target Pengguna",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _minAgeCtrl,
                          label: "Min Usia",
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _maxAgeCtrl,
                          label: "Max Usia",
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // [LAYOUT TIPE KULIT & GENDER SEJAJAR 2:1]
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _skinType,
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
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _targetGender,
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
                          onChanged: (val) =>
                              setState(() => _targetGender = val!),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "SIMPAN PERUBAHAN",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isCurrency = false,
    bool isNumber = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    List<TextInputFormatter> formatters = [];
    if (isCurrency) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      formatters.add(_CurrencyInputFormatter());
    } else if (isNumber) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }

    return TextFormField(
      controller: controller,
      keyboardType: (isCurrency || isNumber)
          ? TextInputType.number
          : TextInputType.text,
      maxLines: maxLines,
      inputFormatters: formatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    if (n.text.isEmpty) return n;
    int val = int.parse(n.text.replaceAll('.', ''));
    final fmt = NumberFormat.decimalPattern('id_ID');
    String newText = fmt.format(val);
    return n.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
