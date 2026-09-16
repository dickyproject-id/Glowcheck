<div align="center">

# ✨ GlowCheck

### 🇮🇩 Aplikasi Analisis & Rekomendasi Produk Skincare Berbasis AI
### 🇬🇧 AI-Powered Skin Analysis & Skincare Product Recommendation App

<br/>

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![TFLite](https://img.shields.io/badge/TFLite-AI%20Model-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)
![ML Kit](https://img.shields.io/badge/ML%20Kit-Face%20Detection-4285F4?style=for-the-badge&logo=google&logoColor=white)

</div>

---

## 🇮🇩 Deskripsi Proyek

**GlowCheck** adalah aplikasi mobile Flutter yang membantu pengguna mengenali **jenis kulit wajah** mereka secara otomatis menggunakan kecerdasan buatan (AI), lalu memberikan **rekomendasi produk skincare** yang paling sesuai berdasarkan hasil analisis tersebut.

Aplikasi ini menggabungkan **Google ML Kit** untuk deteksi wajah, model **TensorFlow Lite** yang dilatih khusus untuk klasifikasi jenis kulit, dan **Firebase** sebagai backend untuk autentikasi, database produk, serta penyimpanan riwayat pengguna.

---

## 🇬🇧 Project Description

**GlowCheck** is a Flutter mobile application that automatically identifies users' **skin type** using artificial intelligence, then provides the most suitable **skincare product recommendations** based on the analysis results.

The app combines **Google ML Kit** for face detection, a custom-trained **TensorFlow Lite** model for skin type classification, and **Firebase** as the backend for authentication, product database, and user history storage.

---

## 🌟 Fitur Lengkap / Full Feature List

### 🤖 AI & Analisis Kulit / AI & Skin Analysis
| 🇮🇩 Bahasa Indonesia | 🇬🇧 English |
|---|---|
| Deteksi wajah otomatis via kamera atau galeri | Automatic face detection via camera or gallery |
| Analisis jenis kulit menggunakan model TFLite | Skin type analysis using a TFLite ML model |
| Klasifikasi 4 jenis kulit: Normal, Berminyak, Kering, Berjerawat | Classification of 4 skin types: Normal, Oily, Dry, Acne-Prone |
| Skor probabilitas detail per kategori kulit | Detailed probability score per skin category |
| Deteksi wajah presisi dengan mode akurat ML Kit | Precise face detection with ML Kit accurate mode |
| Crop & preprocessing wajah otomatis sebelum inferensi | Automatic face crop & preprocessing before inference |

---

### 💄 Rekomendasi Produk / Product Recommendations
| 🇮🇩 Bahasa Indonesia | 🇬🇧 English |
|---|---|
| Rekomendasi produk otomatis berdasarkan jenis kulit | Automatic product recommendations based on skin type |
| Filter berdasarkan kategori produk (Facial Wash, Toner, Serum, dll.) | Filter by product category (Facial Wash, Toner, Serum, etc.) |
| Sorting produk: Paling Cocok, Harga Terendah, Harga Tertinggi | Product sorting: Best Match, Lowest Price, Highest Price |
| Persentase kecocokan produk dengan profil pengguna | Product match percentage with user profile |
| Filter berdasarkan gender & usia pengguna | Filter by user gender & age |
| Tampilan harga online & offline | Display of online & offline pricing |

---

### 🔍 Detail Produk / Product Detail
| 🇮🇩 Bahasa Indonesia | 🇬🇧 English |
|---|---|
| Galeri multi-foto produk | Multi-photo product gallery |
| Informasi lengkap brand, deskripsi, dan bahan (ingredients) | Complete brand, description, and ingredient information |
| Tampilan variasi produk (warna/ukuran) | Product variation display (color/size) |
| Rangkuman persentase kecocokan kulit | Skin match percentage summary |

---

### 📜 Riwayat Analisis / Analysis History
| 🇮🇩 Bahasa Indonesia | 🇬🇧 English |
|---|---|
| Riwayat analisis tersimpan otomatis di cloud (Firestore) | Analysis history automatically saved to cloud (Firestore) |
| Penyimpanan lokal cadangan menggunakan Hive | Local backup storage using Hive |
| Tampilan tanggal & hasil analisis per riwayat | Date & analysis result display per history entry |
| Foto wajah tersimpan per sesi analisis | Facial photo saved per analysis session |

---

### 👤 Autentikasi & Profil / Authentication & Profile
| 🇮🇩 Bahasa Indonesia | 🇬🇧 English |
|---|---|
| Login & Register dengan Email/Password | Login & Register with Email/Password |
| Login dengan Google Account | Login with Google Account |
| Login dengan Apple ID | Login with Apple ID |
| Manajemen profil pengguna (nama, gender, tanggal lahir) | User profile management (name, gender, date of birth) |
| Ubah password akun | Change account password |
| Logout dari semua provider | Logout from all providers |

---

### 🛠️ Admin Panel
| 🇮🇩 Bahasa Indonesia | 🇬🇧 English |
|---|---|
| Panel admin terproteksi dengan kode akses khusus | Admin panel protected with a special access code |
| Tambah produk baru secara manual | Add new products manually |
| Import produk massal via file CSV | Bulk product import via CSV file |
| Upload foto produk dari kamera/galeri | Upload product photos from camera/gallery |
| Edit & hapus data produk | Edit & delete product data |
| Lihat riwayat semua pengguna | View all users' analysis history |
| Manajemen variasi produk | Product variation management |

---

### 🎨 UI / UX
| 🇮🇩 Bahasa Indonesia | 🇬🇧 English |
|---|---|
| Dark Mode & Light Mode | Dark Mode & Light Mode |
| Splash screen animasi | Animated splash screen |
| Efek suara (audioplayers) | Sound effects (audioplayers) |
| Gambar produk dengan cache jaringan | Product images with network cache |
| Desain responsif & modern | Responsive & modern design |

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x / Dart 3.x |
| **State Management** | Provider |
| **Backend & Auth** | Firebase Auth, Cloud Firestore |
| **AI / ML** | TensorFlow Lite, Google ML Kit Face Detection |
| **Local Storage** | Hive |
| **Authentication** | Email/Password, Google Sign-In, Sign in with Apple |
| **Media** | Image Picker, Cached Network Image, File Picker |
| **Data** | CSV Import, UUID |
| **Audio** | AudioPlayers |

---

## ⚙️ Setup Firebase (Wajib / Required)

File konfigurasi Firebase **tidak disertakan** di repo ini karena mengandung API Key rahasia.

> Firebase config files are **not included** in this repo as they contain secret API keys.

### Langkah-langkah / Steps:

**1. Buat project Firebase / Create a Firebase Project**
- Buka / Open: [https://console.firebase.google.com/](https://console.firebase.google.com/)
- Aktifkan: **Authentication**, **Cloud Firestore**, **Firebase Storage**

**2. Setup `lib/firebase_options.dart`**
```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
# Lalu isi dengan nilai dari Firebase Console kamu
# Then fill it with your Firebase Console values
```
> Atau jalankan / Or run: `flutterfire configure`

**3. Setup `android/app/google-services.json`**
```bash
cp android/app/google-services.json.example android/app/google-services.json
# Download file asli dari Firebase Console → Project Settings → Android
```

**4. Setup `ios/Runner/GoogleService-Info.plist`** *(untuk iOS / for iOS)*
- Download dari / Download from: Firebase Console → Project Settings → iOS Apps

---

## 🚀 Menjalankan Aplikasi / Running the App

```bash
# 1. Install dependencies
flutter pub get

# 2. Jalankan / Run
flutter run
```

---

## 📁 Struktur Proyek / Project Structure

```
lib/
├── core/
│   └── theme.dart              # Design system & tema
├── data/
│   ├── models/
│   │   ├── skincare_model.dart # Model Product & AnalysisResult
│   │   └── user_model.dart     # Model UserProfile
│   └── services/
│       ├── firebase_service.dart       # Firebase operations
│       ├── google_auth_service.dart    # Google Sign-In
│       └── real_skin_service.dart      # AI skin analysis (TFLite + ML Kit)
├── providers/
│   └── app_provider.dart       # Global state management
├── ui/
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── result_screen.dart
│   │   ├── product_detail_screen.dart
│   │   ├── product_history_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── edit_product_screen.dart
│   │   └── admin_screen.dart
│   └── widgets/
│       └── product_image.dart
└── main.dart
```

---

<div align="center">

**© 2026 GlowCheck - Muhammad Dicky Adicandra**

</div>
