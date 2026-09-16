import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

import '../data/models/skincare_model.dart';
import '../data/models/user_model.dart';
import '../data/services/firebase_service.dart';
import '../data/services/google_auth_service.dart';
import '../data/services/real_skin_service.dart';

class AppProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Box _historyBox = Hive.box('historyBox');

  final RealSkinService _skinService = RealSkinService();
  final GoogleAuthService _googleService = GoogleAuthService();
  final FirebaseService _firebaseService = FirebaseService();

  // --- STATE VARIABLES ---
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDarkMode = false;

  User? _user;
  UserModel? _currentUserData;
  bool _isAdmin = false;

  // --- ANALYSIS STATE ---
  AnalysisResult? _currentResult;
  List<AnalysisResult> _historyList = [];

  // --- PRODUCT & FILTER STATE ---
  List<Product> _allMatchedProducts = [];
  List<Product> _displayedRecommendations = [];

  // Filter Kategori
  List<String> _availableCategories = ['Semua'];
  String _selectedCategory = 'Semua';

  // [BARU] Filter Sorting
  String _currentSortOption = 'Paling Cocok'; // Default

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  User? get user => _user;
  UserModel? get currentUser => _currentUserData;
  bool get isAdmin => _isAdmin;

  AnalysisResult? get currentResult => _currentResult;
  List<AnalysisResult> get history => _historyList;

  List<Product> get recommendations => _displayedRecommendations;
  List<String> get availableCategories => _availableCategories;
  String get selectedCategory => _selectedCategory;
  String get currentSortOption => _currentSortOption; // Getter Sort

  String? get userName =>
      _currentUserData?.fullName ?? _user?.displayName ?? 'Guest';

  // --- CONSTRUCTOR ---
  AppProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _fetchUserProfile(user.uid);
        fetchHistory();
      } else {
        _currentUserData = null;
        _historyList = [];
      }
      notifyListeners();
    });
  }

  // =========================================================
  //  1. THEME MANAGEMENT
  // =========================================================
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // =========================================================
  //  2. AUTHENTICATION & USER PROFILE
  // =========================================================

  Future<bool> loginUser(String email, String password) async {
    return _handleAuth(
      () => _auth.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  Future<bool> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String gender,
    required DateTime dob,
  }) async {
    _setLoading(true);
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        fullName: fullName,
        gender: gender,
        dob: dob,
        photoProfile: null,
      );
      await _db.collection('users').doc(cred.user!.uid).set(newUser.toMap());
      _currentUserData = newUser;
      _user = cred.user;
      fetchHistory();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Registrasi Gagal: $e");
      return false;
    }
  }

  Future<bool> loginGoogle() async {
    _setLoading(true);
    try {
      User? gUser = await _googleService.signInWithGoogle();
      if (gUser != null) {
        _user = gUser;
        await _checkAndCreateProfile(_user!);
        fetchHistory();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError("Google Login Error: $e");
      return false;
    }
  }

  Future<bool> loginApple() async {
    try {
      _setLoading(true);
      final appleId = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final credential = OAuthProvider('apple.com').credential(
        idToken: appleId.identityToken,
        accessToken: appleId.authorizationCode,
      );
      await _auth.signInWithCredential(credential);
      _user = _auth.currentUser;
      await _checkAndCreateProfile(_user!);
      fetchHistory();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Apple Login Error: $e");
      return false;
    }
  }

  Future<bool> loginAdmin(String code) async {
    _setLoading(true);
    if (code == "Admin@glowcheck") {
      _isAdmin = true;
      _setLoading(false);
      return true;
    }
    _setError("Kode Salah");
    return false;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleService.signOut();
    _user = null;
    _currentUserData = null;
    _isAdmin = false;
    _currentResult = null;
    _historyList = [];
    notifyListeners();
  }

  Future<bool> updateProfile(
    String name,
    String gender,
    DateTime dob,
    String? photoBase64,
  ) async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      final uid = _user!.uid;
      Map<String, dynamic> data = {
        'fullName': name,
        'gender': gender,
        'dob': dob.toIso8601String(),
      };
      if (photoBase64 != null) data['photoProfile'] = photoBase64;

      await _db.collection('users').doc(uid).update(data);

      if (_currentUserData != null) {
        _currentUserData = UserModel(
          uid: uid,
          email: _currentUserData!.email,
          fullName: name,
          gender: gender,
          dob: dob,
          photoProfile: photoBase64 ?? _currentUserData!.photoProfile,
        );
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal Update: $e");
      return false;
    }
  }

  Future<bool> changePassword(String newPass) async {
    _setLoading(true);
    try {
      await _user?.updatePassword(newPass);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal ganti password: $e");
      return false;
    }
  }

  // --- INTERNAL AUTH HELPERS ---
  Future<bool> _handleAuth(Future Function() authMethod) async {
    _setLoading(true);
    try {
      UserCredential cred = await authMethod();
      _user = cred.user;
      await _fetchUserProfile(_user!.uid);
      fetchHistory();
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? "Auth Error");
      return false;
    }
  }

  Future<void> _checkAndCreateProfile(User firebaseUser) async {
    DocumentSnapshot doc = await _db
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (doc.exists) {
      _currentUserData = UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } else {
      UserModel newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? "",
        fullName: firebaseUser.displayName ?? "User Baru",
        gender: "Wanita",
        dob: DateTime(2000),
        photoProfile: null,
      );
      await _db.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
      _currentUserData = newUser;
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUserData = UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  // =========================================================
  //  3. ADMIN PRODUCT MANAGEMENT (CRUD)
  // =========================================================

  Future<bool> addProduct(Product product) async {
    try {
      _setLoading(true);
      await _db.collection('products').doc(product.id).set(product.toMap());
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal menambahkan produk: $e");
      return false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('products').doc(productId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint("Error delete product: $e");
      _setError("Gagal menghapus produk: $e");
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _db.collection('products').doc(product.id).update(product.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint("Error update product: $e");
      _setError("Gagal update produk: $e");
    }
  }

  // =========================================================
  //  4. SCANNING & ANALYSIS LOGIC
  // =========================================================

  Future<int> _countFaces(File imageFile) async {
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

  Future<void> analyzeImage(File image) async {
    _setLoading(true);
    _currentResult = null;
    _allMatchedProducts = [];
    _displayedRecommendations = [];
    _errorMessage = null;

    try {
      int faceCount = await _countFaces(image);
      if (faceCount == 0) {
        _setError("Wajah tidak terdeteksi. Pastikan pencahayaan cukup.");
        return;
      } else if (faceCount > 1) {
        _setError(
          "Terdeteksi $faceCount wajah! Harap foto sendiri (1 wajah saja).",
        );
        return;
      }

      Map<String, dynamic> analysis = await _skinService.analyzeRealImage(
        image.path,
      );
      String skinType = analysis['skinType'];
      bool hasMoles = analysis.containsKey('hasMoles')
          ? analysis['hasMoles']
          : false;
      String localPath = await _saveImageLocally(image);

      // Jalankan matching produk
      await _fetchAndMatchProducts(skinType);

      _currentResult = AnalysisResult(
        id: const Uuid().v4(),
        localImagePath: localPath,
        skinType: skinType,
        hasMoles: hasMoles,
        details: analysis['details'],
        date: DateTime.now(),
        recommendations: _displayedRecommendations,
      );

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError("Gagal Analisis: $e");
    }
  }

  Future<bool> scanAndAnalyze(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) {
        _setLoading(false);
        return false;
      }
      await analyzeImage(File(image.path));
      return _currentResult != null;
    } catch (e) {
      _setError("Gagal scan: $e");
      return false;
    }
  }

  Future<String> _saveImageLocally(File tempImage) async {
    final directory = await getApplicationDocumentsDirectory();
    final String fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String localPath = '${directory.path}/$fileName';
    await tempImage.copy(localPath);
    return localPath;
  }

  void resetAnalysis() {
    _currentResult = null;
    _allMatchedProducts = [];
    _displayedRecommendations = [];
    notifyListeners();
  }

  // =========================================================
  //  5. PRODUCT MATCHING & FILTERING
  // =========================================================

  Future<void> _fetchAndMatchProducts(String userSkinType) async {
    try {
      QuerySnapshot snapshot = await _db.collection('products').get();
      List<Product> allProducts = snapshot.docs.map((doc) {
        return Product.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      List<Product> matchedProducts = [];
      String userGender = _currentUserData?.gender ?? 'Unisex';
      int userAge = _currentUserData?.age ?? 25;
      String targetType = userSkinType.toLowerCase().trim();

      for (var product in allProducts) {
        bool isGenderMatch = false;
        String prodGender = product.targetGender;
        if (prodGender == 'Unisex')
          isGenderMatch = true;
        else if (userGender == 'Pria' && prodGender == 'Pria')
          isGenderMatch = true;
        else if (userGender == 'Wanita' && prodGender == 'Wanita')
          isGenderMatch = true;

        bool isAgeMatch = true;
        if (product.minAge > 0 || product.maxAge < 100) {
          isAgeMatch = (userAge >= product.minAge && userAge <= product.maxAge);
        }

        if (isGenderMatch && isAgeMatch) {
          int percent = 0;
          String pType = product.skinType.toLowerCase().trim();
          bool isSkinMatch = false;

          if (pType.contains('all') || pType.contains('semua')) {
            percent = 85;
            isSkinMatch = true;
          } else if (pType.contains(targetType) || targetType.contains(pType)) {
            percent = 95;
            isSkinMatch = true;
          } else if (targetType.contains('kombinasi') &&
              (pType.contains('berminyak') || pType.contains('kering'))) {
            percent = 80;
            isSkinMatch = true;
          } else if (targetType.contains('normal')) {
            if (!pType.contains('jerawat')) {
              percent = 70;
              isSkinMatch = true;
            }
          }

          if (isSkinMatch) {
            product.matchPercent = percent;
            matchedProducts.add(product);
          }
        }
      }

      // Default Sort: Paling Cocok
      matchedProducts.sort((a, b) {
        int cmp = b.matchPercent.compareTo(a.matchPercent);
        if (cmp != 0) return cmp;
        return a.priceOnlineMin.compareTo(b.priceOnlineMin);
      });

      _allMatchedProducts = matchedProducts;
      _displayedRecommendations = List.from(matchedProducts);
      _selectedCategory = 'Semua';
      _currentSortOption = 'Paling Cocok'; // Reset sort

      Set<String> cats = {'Semua'};
      for (var p in matchedProducts) {
        if (p.category.isNotEmpty) cats.add(p.category);
      }
      _availableCategories = cats.toList();
    } catch (e) {
      debugPrint("Match Error: $e");
    }
  }

  // --- LOGIKA FILTER KATEGORI ---
  void filterByCategory(String category) {
    _selectedCategory = category;

    // 1. Filter dulu
    List<Product> temp;
    if (category == 'Semua') {
      temp = List.from(_allMatchedProducts);
    } else {
      temp = _allMatchedProducts
          .where((p) => p.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    // 2. Lalu Sort sesuai pilihan aktif
    _applySort(temp);
  }

  // --- [BARU] LOGIKA SORTING (HARGA/COCOK) ---
  void sortProducts(String sortOption) {
    _currentSortOption = sortOption;
    // Ambil list yang sedang tampil (sudah terfilter kategori)
    List<Product> temp = List.from(_displayedRecommendations);
    _applySort(temp);
  }

  void _applySort(List<Product> list) {
    switch (_currentSortOption) {
      case 'Harga Terendah':
        list.sort((a, b) => a.priceOnlineMin.compareTo(b.priceOnlineMin));
        break;
      case 'Harga Tertinggi':
        list.sort((a, b) => b.priceOnlineMin.compareTo(a.priceOnlineMin));
        break;
      case 'Paling Cocok':
      default:
        list.sort((a, b) {
          int cmp = b.matchPercent.compareTo(a.matchPercent); // % Tinggi dulu
          if (cmp != 0) return cmp;
          return a.priceOnlineMin.compareTo(b.priceOnlineMin); // Harga murah
        });
        break;
    }
    _displayedRecommendations = list;
    notifyListeners();
  }

  // =========================================================
  //  6. HISTORY MANAGEMENT
  // =========================================================

  Future<void> saveHistoryToFirebase() async {
    if (_currentResult == null || _user == null) return;
    _setLoading(true);
    try {
      File imageFile = File(_currentResult!.localImagePath);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Simpan rekomendasi saat ini (yang sedang ditampilkan user)
      List<Product> productsToSave = _displayedRecommendations.isNotEmpty
          ? _displayedRecommendations
          : _allMatchedProducts;

      _currentResult = AnalysisResult(
        id: _currentResult!.id,
        localImagePath: _currentResult!.localImagePath,
        skinType: _currentResult!.skinType,
        hasMoles: _currentResult!.hasMoles,
        details: _currentResult!.details,
        date: _currentResult!.date,
        recommendations: productsToSave,
      );

      Map<String, dynamic> data = _currentResult!.toMap();
      data['userId'] = _user!.uid;
      data['timestamp'] = FieldValue.serverTimestamp();
      data['imageBase64'] = base64Image;
      data.remove('localImagePath');
      data['recommendations'] = productsToSave.map((p) => p.toMap()).toList();

      DocumentReference docRef = await _firebaseService.saveHistory(data);

      AnalysisResult newItem = AnalysisResult(
        id: docRef.id,
        localImagePath: _currentResult!.localImagePath,
        skinType: _currentResult!.skinType,
        hasMoles: _currentResult!.hasMoles,
        details: _currentResult!.details,
        date: DateTime.now(),
        recommendations: productsToSave,
      );

      _historyList.insert(0, newItem);
      _currentResult = newItem;

      Map<String, dynamic> localMap = newItem.toMap();
      localMap['id'] = docRef.id;
      localMap['userId'] = _user!.uid;
      localMap['recommendations'] = productsToSave
          .map((p) => p.toMap())
          .toList();

      await _historyBox.put(docRef.id, localMap);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError("Gagal menyimpan riwayat: $e");
    }
  }

  Future<void> fetchHistory() async {
    if (_user == null) return;
    try {
      final remoteData = await _firebaseService.fetchUserHistory(_user!.uid);
      if (remoteData.isNotEmpty) {
        _historyList = remoteData.map((data) {
          String imagePath = "";
          if (data['imageBase64'] != null) {
            imagePath = "base64,${data['imageBase64']}";
          } else {
            imagePath = data['localImagePath'] ?? "";
          }
          data['localImagePath'] = imagePath;
          return AnalysisResult.fromMap(data);
        }).toList();

        for (var item in _historyList) {
          Map<String, dynamic> localMap = item.toMap();
          localMap.remove('timestamp');
          localMap['userId'] = _user!.uid;
          localMap['recommendations'] = item.recommendations
              .map((p) => p.toMap())
              .toList();
          await _historyBox.put(item.id, localMap);
        }
      } else {
        _loadFromLocalHive();
      }
    } catch (e) {
      _loadFromLocalHive();
    }
    notifyListeners();
  }

  void _loadFromLocalHive() {
    if (_user == null) return;
    final localData = _historyBox.values
        .map((e) {
          try {
            final map = Map<String, dynamic>.from(e);
            if (map['userId'] != _user!.uid) return null;
            return AnalysisResult.fromMap(map);
          } catch (err) {
            return null;
          }
        })
        .where((e) => e != null)
        .cast<AnalysisResult>()
        .toList();

    localData.sort((a, b) => b.date.compareTo(a.date));
    _historyList = localData;
  }

  Future<void> deleteHistory(String historyId) async {
    try {
      await _firebaseService.deleteHistory(historyId);
      await _historyBox.delete(historyId);
      _historyList.removeWhere((item) => item.id == historyId);
      notifyListeners();
    } catch (e) {
      await _historyBox.delete(historyId);
      _historyList.removeWhere((item) => item.id == historyId);
      notifyListeners();
    }
  }

  void setViewResult(AnalysisResult res) {
    _currentResult = res;
    _fetchAndMatchProducts(res.skinType).then((_) {
      if (_currentResult != null) {
        _currentResult = AnalysisResult(
          id: _currentResult!.id,
          localImagePath: _currentResult!.localImagePath,
          skinType: _currentResult!.skinType,
          hasMoles: _currentResult!.hasMoles,
          details: _currentResult!.details,
          date: _currentResult!.date,
          recommendations: _displayedRecommendations,
        );
        notifyListeners();
      }
    });
    notifyListeners();
  }

  // --- UTILS ---
  void _setLoading(bool val) {
    _isLoading = val;
    if (val) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _isLoading = false;
    notifyListeners();
  }
}
