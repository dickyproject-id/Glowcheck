import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _gender = 'Wanita';
  DateTime _dob = DateTime(2000);

  bool _isPassVisible = false;
  bool _isConfirmVisible = false;

  void _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
  }

  void _submit() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password tidak sama!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    bool success = await provider.registerUser(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      fullName: _nameCtrl.text,
      gender: _gender,
      dob: _dob,
    );

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (r) => false,
      );
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // [THEME] Warna Adaptif
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    // Aksen Warna
    final accentColor = isDark ? AppColors.salmon : AppColors.deepTeal;
    final titleColor = isDark ? AppColors.brightYellow : AppColors.deepTeal;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Daftar Akun Baru",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Buat Akun",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Lengkapi data dirimu untuk analisis yang akurat",
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 30),

            _buildTextField(
              controller: _nameCtrl,
              label: "Nama Lengkap",
              icon: Icons.person_outline,
              context: context,
              accentColor: accentColor,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailCtrl,
              label: "Email",
              icon: Icons.email_outlined,
              inputType: TextInputType.emailAddress,
              context: context,
              accentColor: accentColor,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _passCtrl,
              label: "Password",
              icon: Icons.lock_outline,
              isObscure: !_isPassVisible,
              context: context,
              accentColor: accentColor,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPassVisible ? Icons.visibility : Icons.visibility_off,
                  color: accentColor,
                ),
                onPressed: () =>
                    setState(() => _isPassVisible = !_isPassVisible),
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _confirmCtrl,
              label: "Konfirmasi Password",
              icon: Icons.lock_outline,
              isObscure: !_isConfirmVisible,
              context: context,
              accentColor: accentColor,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmVisible ? Icons.visibility : Icons.visibility_off,
                  color: accentColor,
                ),
                onPressed: () =>
                    setState(() => _isConfirmVisible = !_isConfirmVisible),
              ),
            ),
            const SizedBox(height: 16),

            // GENDER DROPDOWN
            DropdownButtonFormField<String>(
              value: _gender,
              items: ['Pria', 'Wanita']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: TextStyle(color: textColor)),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _gender = val.toString()),
              dropdownColor: cardColor,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                labelText: "Jenis Kelamin",
                labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.wc, color: accentColor),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // DATE PICKER
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: accentColor),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tanggal Lahir",
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMMM yyyy').format(_dob),
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            if (provider.isLoading)
              const CircularProgressIndicator(color: AppColors.deepTeal)
            else
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "DAFTAR SEKARANG",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
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
    TextInputType inputType = TextInputType.text,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: inputType,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor?.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: accentColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
