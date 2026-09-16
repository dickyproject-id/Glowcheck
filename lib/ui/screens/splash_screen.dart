import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Animasi Scale (Membesar)
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    // Animasi Opacity (Muncul pelan)
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    try {
      await _audioPlayer.play(AssetSource('audio/intro_sound.mp3'));
    } catch (e) {
      debugPrint("Gagal putar audio: $e");
    }
    // Tunggu durasi splash
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    Widget nextScreen = (provider.user != null)
        ? const HomeScreen()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. LOGO ANIMASI (TANPA BACKGROUND)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: child,
                  ),
                );
              },
              // [FIX] Langsung Image tanpa Container/Circle Background
              child: SizedBox(
                width: 150, // Ukuran logo disesuaikan agar proporsional
                height: 150,
                child: Image.asset(
                  'assets/images/logo_glowcheck.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. TEKS BRANDING
            FadeTransition(
              opacity: _opacityAnimation,
              child: Column(
                children: [
                  Text(
                    "GLOWCHECK",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mustard,
                      letterSpacing: 5.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SKINCARE",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mustard,
                      letterSpacing: 8.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
