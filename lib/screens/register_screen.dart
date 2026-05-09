import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/rekap_theme.dart';
import '../widgets/loading_indicator.dart';

/// Register screen — creates a new account via Laravel API.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onRegisterSuccess});
  final VoidCallback onRegisterSuccess;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nisnController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String _selectedRole = 'parent';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nisnController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final nisn = _nisnController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Nama, email, dan password harus diisi');
      return;
    }
    if (_selectedRole == 'parent' && nisn.isEmpty) {
      setState(() => _errorMessage = 'NISN anak wajib diisi untuk registrasi sebagai Orang Tua');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password minimal 6 karakter');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService.instance.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: confirm,
        role: _selectedRole,
        studentNisn: _selectedRole == 'parent' ? nisn : null,
      );

      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop({
          'success': true,
          'email': email,
          'message': 'Akun berhasil dibuat. Silakan tunggu konfirmasi Admin untuk login.',
        });
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RekapTheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Akun',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: RekapTheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daftar untuk mulai menggunakan REKAPAF',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: RekapTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // ── Error ─────────────────────────────────────
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: RekapTheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: RekapTheme.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: RekapTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Name ─────────────────────────────────────
              _buildTextField(
                controller: _nameController,
                label: 'Nama Lengkap',
                icon: Icons.person_outlined,
              ),
              const SizedBox(height: 16),

              // ── Email ─────────────────────────────────────
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // ── Role Selector ─────────────────────────────
              Text(
                'Daftar sebagai',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: RekapTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _RoleChip(
                      label: 'Orang Tua',
                      icon: Icons.family_restroom,
                      isSelected: _selectedRole == 'parent',
                      onTap: () => setState(() => _selectedRole = 'parent'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoleChip(
                      label: 'Guru',
                      icon: Icons.school,
                      isSelected: _selectedRole == 'guru',
                      onTap: () => setState(() => _selectedRole = 'guru'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── NISN (Parent only) ────────────────────────
              if (_selectedRole == 'parent') ...[
                _buildTextField(
                  controller: _nisnController,
                  label: 'NISN Anak',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan NISN anak untuk menghubungkan akun (wajib)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: RekapTheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Password ──────────────────────────────────
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outlined,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: RekapTheme.outline,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),

              // ── Confirm Password ──────────────────────────
              _buildTextField(
                controller: _confirmController,
                label: 'Konfirmasi Password',
                icon: Icons.lock_outlined,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: RekapTheme.outline,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 28),

              // ── Register Button ───────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _register,
                  style: FilledButton.styleFrom(
                    backgroundColor: RekapTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const LoadingIndicator(size: 22)
                      : const Text(
                          'Daftar',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Back to Login ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: RekapTheme.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: RekapTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
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
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Inter', color: RekapTheme.outline),
        prefixIcon: Icon(icon, color: RekapTheme.outline, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: RekapTheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RekapTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? RekapTheme.primaryContainer : RekapTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? RekapTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? RekapTheme.primary : RekapTheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? RekapTheme.primary : RekapTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
