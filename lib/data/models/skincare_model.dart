import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// 1. CLASS VARIATION (Variasi Produk)
// ==========================================
class Variation {
  final String name;
  final int imageIndex;

  Variation({required this.name, required this.imageIndex});

  factory Variation.fromMap(Map<String, dynamic> map) {
    return Variation(
      name: map['name'] ?? '',
      imageIndex: map['imageIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'imageIndex': imageIndex};
  }
}

// ==========================================
// 2. CLASS PRODUCT (Data Produk)
// ==========================================
class Product {
  final String id;
  final String name;
  final String brand;
  final String category;

  final double priceOnlineMin;
  final double priceOnlineMax;
  final double priceOfflineMin;
  final double priceOfflineMax;

  final String description;
  final String ingredients;

  // Gambar
  final String imageAsset;
  final List<String> images;

  // Filter
  final String skinType;
  final String targetGender;
  final int minAge;
  final int maxAge;

  final List<Variation> variations;

  // UI Helper
  int matchPercent;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.priceOnlineMin,
    required this.priceOnlineMax,
    required this.priceOfflineMin,
    required this.priceOfflineMax,
    required this.description,
    required this.ingredients,
    required this.imageAsset,
    required this.images,
    required this.skinType,
    required this.targetGender,
    required this.minAge,
    required this.maxAge,
    this.variations = const [],
    this.matchPercent = 0,
  });

  // Factory: Convert dari Firebase Map ke Object
  factory Product.fromFirestore(Map<String, dynamic> data, String docId) {
    List<String> parsedImages = List<String>.from(data['images'] ?? []);

    return Product(
      id: docId,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',

      priceOnlineMin: (data['priceOnlineMin'] ?? 0).toDouble(),
      priceOnlineMax: (data['priceOnlineMax'] ?? 0).toDouble(),
      priceOfflineMin: (data['priceOfflineMin'] ?? 0).toDouble(),
      priceOfflineMax: (data['priceOfflineMax'] ?? 0).toDouble(),

      description: data['description'] ?? '',
      ingredients: data['ingredients'] ?? '',

      imageAsset:
          data['imageAsset'] ??
          (parsedImages.isNotEmpty ? parsedImages.first : ''),
      images: parsedImages,

      skinType: data['skinType'] ?? 'Normal',
      targetGender: data['targetGender'] ?? 'Unisex',
      minAge: int.tryParse(data['minAge'].toString()) ?? 0,
      maxAge: int.tryParse(data['maxAge'].toString()) ?? 100,

      variations:
          (data['variations'] as List<dynamic>?)
              ?.map((v) => Variation.fromMap(v))
              .toList() ??
          [],

      matchPercent: data['matchPercent'] ?? 0,
    );
  }

  // Convert Object ke Map (PENTING untuk Simpan ke DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'priceOnlineMin': priceOnlineMin,
      'priceOnlineMax': priceOnlineMax,
      'priceOfflineMin': priceOfflineMin,
      'priceOfflineMax': priceOfflineMax,
      'description': description,
      'ingredients': ingredients,
      'imageAsset': imageAsset,
      'images': images,
      'skinType': skinType,
      'targetGender': targetGender,
      'minAge': minAge,
      'maxAge': maxAge,
      'variations': variations.map((v) => v.toMap()).toList(),
      'matchPercent': matchPercent,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

// ==========================================
// 3. CLASS ANALYSIS RESULT (Riwayat)
// ==========================================
class AnalysisResult {
  final String id;
  final String localImagePath;
  final String skinType;
  final bool hasMoles;
  final Map<String, dynamic> details;
  final DateTime date;
  final List<Product> recommendations;

  AnalysisResult({
    required this.id,
    required this.localImagePath,
    required this.skinType,
    required this.hasMoles,
    required this.details,
    required this.date,
    required this.recommendations,
  });

  // Convert ke Map (Untuk Firebase)
  Map<String, dynamic> toMap() {
    return {
      'localImagePath': localImagePath,
      'skinType': skinType,
      'hasMoles': hasMoles,
      'details': details,
      // Pastikan rekomendasi tersimpan sebagai List Map
      'recommendations': recommendations.map((p) => p.toMap()).toList(),
      'date': date.toIso8601String(),
    };
  }

  // Factory dari Firestore
  factory AnalysisResult.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AnalysisResult(
      id: doc.id,
      localImagePath: data['localImagePath'] ?? '',
      skinType: data['skinType'] ?? 'Normal',
      hasMoles: data['hasMoles'] ?? false,
      details: Map<String, dynamic>.from(data['details'] ?? {}),
      date: parseDate(data['timestamp'] ?? data['date']),
      recommendations:
          (data['recommendations'] as List<dynamic>?)
              ?.map((x) => Product.fromFirestore(x, x['id'] ?? ''))
              .toList() ??
          [],
    );
  }

  // Factory dari Hive (Lokal)
  factory AnalysisResult.fromMap(Map<dynamic, dynamic> map) {
    return AnalysisResult(
      id: map['id'] ?? '',
      localImagePath: map['localImagePath'] ?? '',
      skinType: map['skinType'] ?? 'Normal',
      hasMoles: map['hasMoles'] ?? false,
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      recommendations:
          (map['recommendations'] as List<dynamic>?)
              ?.map((x) => Product.fromFirestore(x, x['id'] ?? ''))
              .toList() ??
          [],
    );
  }
}
