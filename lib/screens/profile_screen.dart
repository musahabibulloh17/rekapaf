import 'package:flutter/material.dart';

import '../data/rekap_repository.dart';
import '../services/auth_service.dart';
import '../theme/rekap_theme.dart';
import '../widgets/loading_indicator.dart';
import 'account_management_screen.dart';
import 'master_data_screen.dart';

/// Profile Screen – shows user info, settings, and logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onLogout,
    this.onRefresh,
    // Legacy: kept for backward compat but no longer used
    VoidCallback? onRoleChanged,
  });

  final VoidCallback onLogout;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final user = RekapRepository.instance.currentUser;

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            // ── Profile Header ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: RekapTheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name.characters.first : '?',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: RekapTheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      user.isSuperAdmin
                          ? 'Super Admin'
                          : (user.isGuru
                                ? 'Guru'
                                : (user.isParent
                                      ? 'Orang Tua / Wali'
                                      : 'Wali Kelas')),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Menu Items ──────────────────────────────────
            const _SectionLabel('Pengaturan'),
            const SizedBox(height: 8),
            _MenuItem(icon: Icons.notifications_outlined, title: 'Notifikasi'),
            _MenuItem(icon: Icons.lock_outlined, title: 'Ubah Password'),
            const SizedBox(height: 16),

            const _SectionLabel('Lainnya'),
            const SizedBox(height: 8),
            if (user.isSuperAdmin) ...[
              _MenuItem(
                icon: Icons.dataset_outlined,
                title: 'Master Data',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MasterDataScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.manage_accounts_outlined,
                title: 'Kelola Akun',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountManagementScreen(),
                    ),
                  );
                },
              ),
            ],
            _MenuItem(icon: Icons.help_outline, title: 'Bantuan & FAQ'),
            _MenuItem(
              icon: Icons.info_outline,
              title: 'Tentang Aplikasi',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text(
                      'Tentang Aplikasi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: const Text(
                      'Aplikasi REKAPAF dirancang untuk memudahkan pemantauan dan pengelolaan akademik serta disiplin siswa secara real-time.\n\n'
                      'Aplikasi ini dikembangkan oleh lulusan Sma Al Furqan Jember, yaitu:\n'
                      '• Musa Habibulloh Al Faruq (Teknik Informatika, Polije)\n'
                      '• Umar Khoththob (Teknik Elektro, Unej)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Logout Button ───────────────────────────────
            _LogoutButton(onLogout: onLogout),
            const SizedBox(height: 24),

            // ── Version ─────────────────────────────────────
            Center(
              child: Text(
                'REKAPAF v1.0.0',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: RekapTheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: RekapTheme.outline,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.title, this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: RekapTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: RekapTheme.onSurfaceVariant, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: RekapTheme.onSurface,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: RekapTheme.outline,
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap ?? () {},
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _LogoutButton extends StatefulWidget {
  const _LogoutButton({required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isLoading = false;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar dari Akun',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar?',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: RekapTheme.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    await AuthService.instance.logout();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _logout,
        icon: _isLoading
            ? const LoadingIndicator(size: 18)
            : const Icon(Icons.logout, color: RekapTheme.error),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: RekapTheme.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: RekapTheme.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
