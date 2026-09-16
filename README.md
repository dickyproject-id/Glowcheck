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

## ✨ Fitur Utama & Struktur Aplikasi (Core Features & App Structure)

---

### 🇮🇩 Bahasa Indonesia

**A. Analisis Kulit Berbasis AI**

- 🤖 **Deteksi Wajah Otomatis:** Mendeteksi wajah secara presisi dari foto kamera maupun galeri menggunakan Google ML Kit mode akurat.
- 🧠 **Klasifikasi Jenis Kulit:** Menganalisis jenis kulit menggunakan model TensorFlow Lite yang dilatih khusus untuk 4 kategori kulit.
- 🔬 **4 Kategori Jenis Kulit:** Normal, Berminyak, Kering, dan Berjerawat — masing-masing dengan skor probabilitas detail.
- ✂️ **Preprocessing Otomatis:** Wajah di-crop dan di-resize secara otomatis ke 224×224 sebelum diproses model AI.

**B. Rekomendasi Produk Skincare**

- 💄 **Rekomendasi Personal:** Produk skincare direkomendasikan secara otomatis berdasarkan jenis kulit hasil analisis.
- 🏷️ **Filter Kategori Produk:** Filter produk berdasarkan kategori (Facial Wash, Toner, Serum, Moisturizer, Sunscreen, dll.).
- ↕️ **Sorting Produk:** Urutkan produk berdasarkan Paling Cocok, Harga Terendah, atau Harga Tertinggi.
- 📊 **Persentase Kecocokan:** Setiap produk menampilkan persentase kesesuaian dengan profil kulit dan data pengguna.
- 👤 **Filter Gender & Usia:** Rekomendasi menyesuaikan gender dan rentang usia pengguna yang terdaftar.
- 💰 **Harga Online & Offline:** Setiap produk menampilkan rentang harga online maupun offline.

**C. Detail Produk**

- 🖼️ **Galeri Multi-Foto:** Tampilan beberapa foto produk yang bisa di-scroll dalam satu halaman detail.
- 📋 **Info Lengkap Produk:** Menampilkan brand, deskripsi lengkap, dan daftar bahan (ingredients) produk.
- 🎨 **Variasi Produk:** Mendukung tampilan variasi warna atau ukuran dalam satu produk.

**D. Riwayat Analisis**

- ☁️ **Tersimpan di Cloud:** Riwayat analisis otomatis tersimpan di Firestore dan dapat diakses dari perangkat mana pun.
- 💾 **Backup Lokal:** Riwayat juga disimpan secara lokal menggunakan Hive sebagai cadangan offline.
- 📅 **Riwayat Lengkap:** Setiap entri riwayat menyimpan tanggal, foto wajah, jenis kulit, dan produk rekomendasi saat itu.

**E. Autentikasi & Profil Pengguna**

- 📧 **Login Email/Password:** Daftar dan masuk menggunakan email dan kata sandi.
- 🔵 **Login Google:** Masuk cepat menggunakan akun Google.
- 🍎 **Login Apple ID:** Masuk menggunakan Apple ID (khusus perangkat Apple).
- 👤 **Profil Pengguna:** Kelola data profil seperti nama lengkap, gender, dan tanggal lahir.
- 🔑 **Ubah Password:** Pengguna dapat mengubah kata sandi akun kapan saja.

**F. Admin Panel**

- 🔒 **Akses Terproteksi:** Panel admin hanya bisa diakses dengan kode khusus.
- ➕ **Tambah Produk Manual:** Admin dapat menambahkan produk skincare baru secara manual melalui form.
- 📂 **Import CSV:** Import data produk secara massal dari file CSV sekaligus.
- 📷 **Upload Foto Produk:** Tambahkan foto produk langsung dari kamera atau galeri.
- ✏️ **Edit & Hapus Produk:** Kelola data produk yang sudah ada dengan fitur edit dan hapus.
- 📜 **Lihat Riwayat Semua User:** Admin dapat melihat riwayat analisis seluruh pengguna terdaftar.

**G. Tampilan & Pengalaman Pengguna (UI/UX)**

- 🌙 **Dark Mode & Light Mode:** Tema gelap dan terang yang bisa diubah sewaktu-waktu.
- 🎬 **Splash Screen Animasi:** Layar pembuka dengan animasi yang menarik.
- 🔊 **Efek Suara:** Feedback audio pada interaksi tertentu menggunakan AudioPlayers.
- 🖼️ **Cache Gambar:** Gambar produk dari internet di-cache untuk loading lebih cepat.

---

### 🇬🇧 English

**A. AI-Powered Skin Analysis**

- 🤖 **Automatic Face Detection:** Precisely detects faces from camera photos or gallery using Google ML Kit in accurate mode.
- 🧠 **Skin Type Classification:** Analyzes skin type using a custom-trained TensorFlow Lite model for 4 skin categories.
- 🔬 **4 Skin Type Categories:** Normal, Oily, Dry, and Acne-Prone — each with detailed probability scores.
- ✂️ **Automatic Preprocessing:** Faces are automatically cropped and resized to 224×224 before being processed by the AI model.

**B. Skincare Product Recommendations**

- 💄 **Personalized Recommendations:** Skincare products are automatically recommended based on the skin type from the analysis.
- 🏷️ **Category Filter:** Filter products by category (Facial Wash, Toner, Serum, Moisturizer, Sunscreen, etc.).
- ↕️ **Product Sorting:** Sort products by Best Match, Lowest Price, or Highest Price.
- 📊 **Match Percentage:** Each product displays a compatibility percentage with the user's skin profile and personal data.
- 👤 **Gender & Age Filter:** Recommendations are tailored to the user's registered gender and age range.
- 💰 **Online & Offline Prices:** Each product displays both online and offline price ranges.

**C. Product Detail**

- 🖼️ **Multi-Photo Gallery:** Scroll through multiple product photos on a single detail page.
- 📋 **Complete Product Info:** Displays brand, full description, and ingredients list.
- 🎨 **Product Variations:** Supports displaying color or size variations within a single product.

**D. Analysis History**

- ☁️ **Cloud Saved:** Analysis history is automatically saved to Firestore and accessible from any device.
- 💾 **Local Backup:** History is also stored locally using Hive as an offline fallback.
- 📅 **Full History:** Each history entry stores the date, face photo, skin type, and product recommendations at the time.

**E. Authentication & User Profile**

- 📧 **Email/Password Login:** Register and sign in using email and password.
- 🔵 **Google Login:** Quick sign-in using a Google account.
- 🍎 **Apple ID Login:** Sign in using Apple ID (Apple devices only).
- 👤 **User Profile:** Manage profile data such as full name, gender, and date of birth.
- 🔑 **Change Password:** Users can change their account password at any time.

**F. Admin Panel**

- 🔒 **Protected Access:** The admin panel is accessible only with a special access code.
- ➕ **Manual Product Entry:** Admin can add new skincare products manually via a form.
- 📂 **CSV Import:** Bulk import product data from a CSV file at once.
- 📷 **Upload Product Photos:** Add product photos directly from the camera or gallery.
- ✏️ **Edit & Delete Products:** Manage existing product data with edit and delete features.
- 📜 **View All User Histories:** Admin can view the analysis history of all registered users.

**G. UI/UX**

- 🌙 **Dark Mode & Light Mode:** Switch between dark and light themes at any time.
- 🎬 **Animated Splash Screen:** An attractive animated loading screen on app launch.
- 🔊 **Sound Effects:** Audio feedback on certain interactions using AudioPlayers.
- 🖼️ **Image Caching:** Product images from the internet are cached for faster loading.

---

## 🧰 Tech Stack

- **Framework:** Flutter 3.x / Dart 3.x
- **State Management:** Provider
- **Backend & Database:** Firebase Auth, Cloud Firestore
- **AI / ML:** TensorFlow Lite, Google ML Kit Face Detection
- **Local Storage:** Hive
- **Authentication:** Email/Password, Google Sign-In, Sign in with Apple
- **Media:** Image Picker, Cached Network Image, File Picker
- **Data Import:** CSV
- **Audio:** AudioPlayers
- **Utilities:** UUID, intl, path_provider

---

## ⚙️ Setup Firebase (Wajib / Required)

File konfigurasi Firebase **tidak disertakan** di repo ini karena mengandung API Key rahasia.
Firebase config files are **not included** in this repo as they contain secret API keys.

**1. Buat project Firebase / Create a Firebase Project**
- Buka / Open: [https://console.firebase.google.com/](https://console.firebase.google.com/)
- Aktifkan / Enable: **Authentication**, **Cloud Firestore**

**2. Setup `lib/firebase_options.dart`**
```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
# Isi dengan nilai dari Firebase Console kamu
# Fill it with your Firebase Console values
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
# Install dependencies
flutter pub get

# Jalankan / Run
flutter run
```

---

## 📁 Struktur Proyek / Project Structure

```
lib/
├── core/
│   └── theme.dart                      # Design system & tema
├── data/
│   ├── models/
│   │   ├── skincare_model.dart         # Model Product & AnalysisResult
│   │   └── user_model.dart             # Model UserProfile
│   └── services/
│       ├── firebase_service.dart       # Firebase operations
│       ├── google_auth_service.dart    # Google Sign-In
│       └── real_skin_service.dart      # AI skin analysis (TFLite + ML Kit)
├── providers/
│   └── app_provider.dart               # Global state management
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
