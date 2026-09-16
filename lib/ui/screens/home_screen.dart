import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import 'profile_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchHistory();
    });
  }

  // [CLEAN] Return null if invalid, no asset needed
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
                      color: Colors.white.withValues(alpha: 0.2),
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

  void _navigateToResult(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ResultScreen(isHistoryView: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currentUser = provider.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    final btnScanColor = AppColors.salmon;
    final btnGalleryColor = AppColors.deepTeal;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text(
          "Skincare Analyzer",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline_rounded, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await provider.fetchHistory(),
        color: AppColors.deepTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.deepTeal, Color(0xFF00838F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepTeal.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Halo, ${currentUser?.fullName ?? 'Glowing People'}! ✨",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Gender: ${currentUser?.gender ?? '-'}  |  Usia: ${currentUser?.age ?? '-'} th",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Scan wajahmu sekarang untuk analisis kulit yang lebih akurat.",
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Mulai Analisis",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildScanButton(
                      context,
                      ImageSource.camera,
                      "Kamera",
                      Icons.camera_alt_rounded,
                      btnScanColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildScanButton(
                      context,
                      ImageSource.gallery,
                      "Galeri",
                      Icons.photo_library_rounded,
                      btnGalleryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Riwayat Analisis",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (provider.history.isNotEmpty)
                    Text(
                      "${provider.history.length} Data",
                      style: TextStyle(color: textColor.withOpacity(0.5)),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              if (provider.isLoading && provider.history.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (provider.history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 40,
                        color: textColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Belum ada riwayat scan.",
                        style: TextStyle(color: textColor.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.history.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = provider.history[index];
                    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
                    final imageProvider = _getImageProvider(
                      item.localImagePath,
                    );

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: cardColor,
                            title: Text(
                              "Hapus Riwayat",
                              style: TextStyle(color: textColor),
                            ),
                            content: Text(
                              "Yakin ingin menghapus data ini?",
                              style: TextStyle(color: textColor),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Batal"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  "Hapus",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        provider.deleteHistory(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Riwayat dihapus"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          provider.setViewResult(item);
                          _navigateToResult(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.3 : 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: GestureDetector(
                              onTap: () {
                                if (imageProvider != null) {
                                  _showFullScreenImage(
                                    context,
                                    item.localImagePath,
                                  );
                                }
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.deepTeal,
                                    width: 2,
                                  ),
                                  // [CLEAN] Tampilkan gambar jika valid, null jika tidak
                                  image: imageProvider != null
                                      ? DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: imageProvider == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                            title: Text(
                              "Kulit ${item.skinType}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              dateFormat.format(item.date),
                              style: TextStyle(
                                color: textColor.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton(
    BuildContext context,
    ImageSource source,
    String label,
    IconData icon,
    Color btnColor,
  ) {
    return ElevatedButton(
      onPressed: () async {
        final provider = Provider.of<AppProvider>(context, listen: false);
        bool success = await provider.scanAndAnalyze(source);
        if (success && provider.currentResult != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResultScreen()),
          );
        } else if (context.mounted && provider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage!),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
