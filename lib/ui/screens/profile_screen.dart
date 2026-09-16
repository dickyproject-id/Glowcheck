import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models/user_model.dart';
import '../../providers/app_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;

  String _gender = 'Wanita';
  DateTime _dob = DateTime.now();
  String? _base64Image;
  File? _imageFile;

  // Snapshot Data Awal (Untuk Cek Perubahan)
  UserModel? _initialUser;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppProvider>(context, listen: false).currentUser;
    _initialUser = user;

    _nameController = TextEditingController(text: user?.fullName ?? "");
    _gender = user?.gender ?? "Wanita";
    _dob = user?.dob ?? DateTime.now();

    try {
      _base64Image = (user as dynamic)?.photoProfile;
    } catch (e) {
      _base64Image = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- HELPER SNACKBAR ---
  void _showSnackBar(String message, {bool isError = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isError
        ? Colors.redAccent
        : (isDark ? AppColors.salmon : AppColors.deepTeal);

    final textColor = (isDark && !isError) ? Colors.black : Colors.white;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- LOGIKA CEK PERUBAHAN ---
  bool _hasChanges() {
    if (_initialUser == null) return true;

    bool nameChanged = _nameController.text.trim() != _initialUser!.fullName;
    bool genderChanged = _gender != _initialUser!.gender;
    bool dobChanged = !DateUtils.isSameDay(_dob, _initialUser!.dob);
    bool photoChanged = _imageFile != null;

    return nameChanged || genderChanged || dobChanged || photoChanged;
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (picked != null) {
        if (!mounted) return;
        _showSnackBar("Memproses foto...");

        File imgFile = File(picked.path);
        List<int> imageBytes = await imgFile.readAsBytes();
        String base64String =
            "data:image/jpeg;base64,${base64Encode(imageBytes)}";

        setState(() {
          _imageFile = imgFile;
          _base64Image = base64String;
        });

        // Auto Save khusus foto
        _saveProfile(isAutoSavePhoto: true);
      }
    } catch (e) {
      _showSnackBar("Gagal mengambil foto", isError: true);
    }
  }

  // --- LOGIKA SIMPAN PROFIL ---
  Future<void> _saveProfile({bool isAutoSavePhoto = false}) async {
    // Jika bukan ganti foto DAN tidak ada perubahan data teks -> STOP
    if (!isAutoSavePhoto && !_hasChanges()) {
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    _showSnackBar("Menyimpan profil...");

    bool success = await provider.updateProfile(
      _nameController.text,
      _gender,
      _dob,
      _base64Image,
    );

    if (mounted) {
      if (success) {
        _initialUser = provider.currentUser; // Update state awal
        setState(() {
          _imageFile = null; // Reset file lokal
        });
        _showSnackBar("Profil Berhasil Diupdate!");
      } else {
        _showSnackBar(provider.errorMessage ?? "Gagal update", isError: true);
      }
    }
  }

  void _showChangePasswordDialog() {
    final passController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = Theme.of(context).textTheme.bodyLarge?.color;

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text("Ganti Password", style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passController,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Password Baru",
                  labelStyle: TextStyle(color: textColor?.withOpacity(0.6)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Konfirmasi Password",
                  labelStyle: TextStyle(color: textColor?.withOpacity(0.6)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
            TextButton(
              onPressed: () async {
                if (passController.text.length < 6) {
                  _showSnackBar("Password minimal 6 karakter", isError: true);
                  return;
                }
                if (passController.text != confirmController.text) {
                  _showSnackBar("Password tidak cocok", isError: true);
                  return;
                }

                Navigator.pop(ctx);
                final provider = Provider.of<AppProvider>(
                  context,
                  listen: false,
                );

                bool success = await provider.changePassword(
                  passController.text,
                );

                if (success) {
                  _showSnackBar("Password berhasil diubah!");
                } else {
                  _showSnackBar(
                    provider.errorMessage ?? "Gagal ubah password",
                    isError: true,
                  );
                }
              },
              child: Text(
                "Simpan",
                style: TextStyle(
                  color: isDark ? AppColors.salmon : AppColors.deepTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _viewProfilePhoto(BuildContext context, ImageProvider? imageProvider) {
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

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.salmon,
              ),
              title: const Text("Ambil Foto"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.deepTeal,
              ),
              title: const Text("Pilih dari Galeri"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImageProvider(dynamic user) {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }
    String? photoData;
    try {
      photoData = (user as dynamic)?.photoProfile;
    } catch (e) {
      photoData = null;
    }

    if (photoData != null && photoData.isNotEmpty) {
      try {
        String cleanBase64 = photoData;
        if (photoData.contains(',')) {
          cleanBase64 = photoData.split(',').last;
        }
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        return MemoryImage(base64Decode(cleanBase64));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageProvider = _getProfileImageProvider(user);

    List<String> genderOptions = ['Pria', 'Wanita'];
    if (!genderOptions.contains(_gender)) {
      genderOptions.add(_gender);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil Saya",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // FOTO PROFIL
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (imageProvider != null) {
                      _viewProfilePhoto(context, imageProvider);
                    } else {
                      _showPhotoOptions();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.deepTeal, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepTeal.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: imageProvider,
                      child: (imageProvider == null)
                          ? Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: Colors.grey.shade600,
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.salmon,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          _buildTextField(
            controller: _nameController,
            label: "Nama Lengkap",
            context: context,
          ),
          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            value: _gender,
            items: genderOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: TextStyle(color: textColor)),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _gender = val.toString()),
            dropdownColor: cardColor,
            decoration: InputDecoration(
              labelText: "Jenis Kelamin",
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            tileColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              "Tgl Lahir: ${DateFormat('dd MMM yyyy').format(_dob)}",
              style: TextStyle(color: textColor),
            ),
            trailing: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.deepTeal,
            ),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _dob,
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: isDark
                          ? const ColorScheme.dark(
                              primary: AppColors.deepTeal,
                              onPrimary: Colors.white,
                              onSurface: Colors.white,
                            )
                          : const ColorScheme.light(
                              primary: AppColors.deepTeal,
                              onPrimary: Colors.white,
                              onSurface: AppColors.textDark,
                            ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _dob = picked);
            },
          ),
          const SizedBox(height: 25),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => _saveProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "SIMPAN PERUBAHAN",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(),
          ),

          Text(
            "Pengaturan",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),

          // DARK MODE (Tanpa Notifikasi)
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              secondary: Icon(
                provider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: provider.isDarkMode
                    ? Colors.yellowAccent
                    : AppColors.deepTeal,
              ),
              title: const Text(
                "Mode Gelap",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              activeColor: AppColors.salmon,
              value: provider.isDarkMode,
              onChanged: (_) {
                provider.toggleTheme();
                // Notifikasi _showSnackBar dihapus sesuai permintaan
              },
            ),
          ),
          const SizedBox(height: 10),

          // GANTI PASSWORD
          _buildSettingItem(
            context: context,
            icon: Icons.lock_outline_rounded,
            title: "Ganti Password",
            color: isDark ? AppColors.salmon : AppColors.deepTeal,
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 10),

          // LOGOUT
          _buildSettingItem(
            context: context,
            icon: Icons.logout_rounded,
            title: "Keluar (Logout)",
            color: Colors.redAccent,
            onTap: () async {
              bool confirm =
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: cardColor,
                      title: const Text("Logout"),
                      content: const Text("Yakin ingin keluar?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            "Ya",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (confirm) {
                await provider.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor?.withOpacity(0.5)),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final itemColor = color ?? Theme.of(context).textTheme.bodyLarge!.color!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: itemColor),
        title: Text(
          title,
          style: TextStyle(color: itemColor, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: itemColor.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}
