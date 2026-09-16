import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'ui/screens/splash_screen.dart'; // Pastikan import ini ada

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Init Hive (Database Lokal untuk Riwayat Offline)
  await Hive.initFlutter();
  await Hive.openBox('historyBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'GlowCheck App',

            // --- Konfigurasi Tema ---
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            // Mode tema mengikuti settingan di Provider (bisa diganti user di Profile)
            themeMode: provider.themeMode,

            // --- NAVIGASI UTAMA ---
            // Kita set ke SplashScreen agar logo & audio selalu muncul saat aplikasi dibuka.
            // Nanti SplashScreen yang akan cek status login dan mengarahkan ke Home/Login.
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
