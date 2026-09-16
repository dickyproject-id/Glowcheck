import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import 'admin_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  String? _emailErrorText;
  String? _passErrorText;
  bool _isPasswordVisible = false;
  bool _isAdminCodeVisible = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) _validateEmailFormatOnly();
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _validateEmailFormatOnly() {
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty) {
      final isValid = RegExp(
        r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(email);
      setState(() {
        _emailErrorText = isValid ? null : "Format email salah!";
      });
    }
  }

  bool _validateInputs() {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    setState(() {
      _emailErrorText = null;
      _passErrorText = null;
    });
    if (email.isEmpty) {
      setState(() => _emailErrorText = "Email wajib diisi");
      return false;
    }
    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      setState(() => _emailErrorText = "Format email tidak valid");
      return false;
    }
    if (password.isEmpty) {
      setState(() => _passErrorText = "Password wajib diisi");
      return false;
    }
    return true;
  }

  // --- [FIX: POPUP LOGIN BERHASIL & NAVIGASI BERSIH] ---
  void _showSuccessDialogAndNavigate([bool isAdmin = false]) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Bersihkan notifikasi/snackbar error sebelumnya agar tidak tumpang tindih/nyangkut
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa tutup sembarangan
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: isDark ? AppColors.brightYellow : AppColors.deepTeal,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              isAdmin ? "Login Admin Berhasil!" : "Login Berhasil!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Selamat datang kembali.",
              style: TextStyle(color: textColor?.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );

    // 2. Delay sebentar, lalu tutup dialog dan pindah halaman
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        // Tutup Dialog (menggunakan rootNavigator agar aman)
        Navigator.of(context, rootNavigator: true).pop();

        // Pindah ke Halaman Utama
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin ? const AdminScreen() : const HomeScreen(),
          ),
        );
      }
    });
  }

  void _showAdminDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final cardColor = Theme.of(context).cardColor;
            final textColor = Theme.of(context).textTheme.bodyLarge?.color;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final iconColor = isDark ? AppColors.salmon : AppColors.deepTeal;

            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Admin Login",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              content: TextField(
                controller: codeCtrl,
                obscureText: !_isAdminCodeVisible,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Kode Admin",
                  labelStyle: TextStyle(color: textColor?.withOpacity(0.6)),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isAdminCodeVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: iconColor,
                    ),
                    onPressed: () => setStateDialog(
                      () => _isAdminCodeVisible = !_isAdminCodeVisible,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "BATAL",
                    style: TextStyle(color: textColor?.withOpacity(0.6)),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final provider = Provider.of<AppProvider>(
                      context,
                      listen: false,
                    );
                    bool success = await provider.loginAdmin(
                      codeCtrl.text.trim(),
                    );

                    if (success && mounted) {
                      _showSuccessDialogAndNavigate(
                        true,
                      ); // Panggil Popup Sukses Admin
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Kode Admin Salah!"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Text(
                    "MASUK",
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final accentColor = isDark ? AppColors.salmon : AppColors.deepTeal;
    final logoColor = isDark ? AppColors.brightYellow : AppColors.deepTeal;

    // Redirect jika sudah login (session persistence)
    if (provider.user != null && !provider.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? false) _navigateHome();
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => provider.toggleTheme(),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? Colors.yellowAccent : AppColors.deepTeal,
          ),
          tooltip: "Ganti Tema",
        ),
        actions: [
          TextButton.icon(
            onPressed: _showAdminDialog,
            icon: Icon(
              Icons.admin_panel_settings_rounded,
              color: accentColor,
              size: 20,
            ),
            label: Text("Admin", style: TextStyle(color: textColor)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_glowcheck.png',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                "GLOWCHECK",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: logoColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Login",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Temukan skincare terbaik untuk kulitmu",
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                controller: _emailCtrl,
                label: "Email",
                icon: Icons.email_outlined,
                context: context,
                accentColor: accentColor,
                focusNode: _emailFocusNode,
                errorText: _emailErrorText,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passCtrl,
                label: "Password",
                icon: Icons.lock_outline_rounded,
                context: context,
                accentColor: accentColor,
                isObscure: !_isPasswordVisible,
                errorText: _passErrorText,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: accentColor,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) =>
                              setState(() => _rememberMe = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Ingat Saya",
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Fitur Lupa Password segera hadir!"),
                      ),
                    ),
                    child: Text(
                      "Lupa Password?",
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (!_validateInputs()) return;

                          // Bersihkan snackbar lama sebelum proses login
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();

                          bool success = await provider.loginUser(
                            _emailCtrl.text.trim(),
                            _passCtrl.text,
                          );
                          if (success && mounted) {
                            _showSuccessDialogAndNavigate(
                              false,
                            ); // Panggil Popup Sukses User
                          } else if (mounted && provider.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.errorMessage!),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "MASUK",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: Divider(color: textColor.withOpacity(0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "ATAU",
                      style: TextStyle(
                        color: textColor.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: textColor.withOpacity(0.1))),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _socialButton(
                      leadingWidget: Image.asset(
                        'assets/images/google_logo.png',
                        height: 22,
                        width: 22,
                      ),
                      label: "Google",
                      context: context,
                      onTap: () async {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        if (await provider.loginGoogle() && mounted)
                          _showSuccessDialogAndNavigate(false);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _socialButton(
                      leadingWidget: Icon(
                        Icons.apple,
                        color: textColor,
                        size: 26,
                      ),
                      label: "Apple",
                      context: context,
                      onTap: () async {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        if (await provider.loginApple() && mounted)
                          _showSuccessDialogAndNavigate(false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Belum punya akun?",
                    style: TextStyle(color: textColor.withOpacity(0.6)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: Text(
                      "Daftar Sekarang",
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required BuildContext context,
    required Color accentColor,
    bool isObscure = false,
    Widget? suffixIcon,
    FocusNode? focusNode,
    String? errorText,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isObscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor?.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: accentColor),
        suffixIcon: suffixIcon,
        errorText: errorText,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _socialButton({
    required Widget leadingWidget,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leadingWidget,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
