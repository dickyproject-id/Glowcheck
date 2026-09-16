import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRODUK ---
  Future<void> addProduct(Map<String, dynamic> productData) async {
    await _db.collection('products').add(productData);
  }

  // --- RIWAYAT (HISTORY) ---

  // 1. Simpan Riwayat
  Future<DocumentReference> saveHistory(Map<String, dynamic> data) async {
    try {
      print("🔥 MENCOBA MENYIMPAN KE FIREBASE...");
      DocumentReference doc = await _db.collection('histories').add(data);
      print("✅ BERHASIL DISIMPAN! ID: ${doc.id}");
      return doc;
    } catch (e) {
      print("❌ ERROR FATAL SAAT SIMPAN KE FIREBASE: $e");
      rethrow; // Lempar error biar AppProvider tau kalau ini gagal
    }
  }

  // 2. Ambil Riwayat User
  Future<List<Map<String, dynamic>>> fetchUserHistory(String uid) async {
    try {
      print("🔍 MENGAMBIL DATA RIWAYAT UNTUK USER: $uid");

      // PENTING: Query ini butuh Index (userId ASC, timestamp DESC)
      final snapshot = await _db
          .collection('histories')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      print("✅ DITEMUKAN ${snapshot.docs.length} DATA RIWAYAT.");

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("❌ ERROR FETCH HISTORY: $e");
      // JIKA INDEX SALAH, LINK PERBAIKAN AKAN MUNCUL DI DEBUG CONSOLE (RUN TAB)
      return [];
    }
  }

  // 3. Hapus Riwayat
  Future<void> deleteHistory(String docId) async {
    await _db.collection('histories').doc(docId).delete();
  }
}
