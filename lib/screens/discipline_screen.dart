import 'package:flutter/material.dart';

import '../data/rekap_repository.dart';
import '../models/student.dart';
import '../theme/rekap_theme.dart';

/// Poin Tata Tertib – Discipline Points Screen (User/Parent view)
/// Matches: poin-tata-tertib-user.html
class DisciplineScreen extends StatelessWidget {
  const DisciplineScreen({super.key, this.onRefresh});
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository.instance;
    final student = repo.childStudent;

    if (student == null) {
      return Scaffold(
        backgroundColor: RekapTheme.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, size: 64, color: RekapTheme.outline),
              const SizedBox(height: 16),
              const Text('Belum ada data disiplin', style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final dp = student.disciplinePoints;

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // ── Hero Summary Section ────────────────────────
            _HeroGrid(dp: dp),
            const SizedBox(height: 32),

            // ── Riwayat Poin Header ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Poin',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: RekapTheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    _IconButton(icon: Icons.filter_list),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: RekapTheme.surfaceContainer),
                      ),
                      child: const Text(
                        'Bulan Ini',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: RekapTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Timeline List ───────────────────────────────
            ...dp.records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecordItem(record: record),
              ),
            ),
            const SizedBox(height: 8),

            // ── View More Button ────────────────────────────
            _ViewMoreButton(),
            const SizedBox(height: 32),

            // ── Information Banner ──────────────────────────
            _InfoBanner(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _HeroGrid extends StatelessWidget {
  const _HeroGrid({required this.dp});
  final DisciplinePoints dp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Points Card ─────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                constraints: const BoxConstraints(minHeight: 180),
                decoration: BoxDecoration(
                  color: RekapTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL POIN DISIPLIN',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: RekapTheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dp.totalPoints.toString(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: RekapTheme.onPrimaryContainer,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: RekapTheme.onPrimaryContainer
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Predikat: ${dp.predicate}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: RekapTheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.verified_user,
                        size: 120,
                        color: RekapTheme.onPrimaryContainer
                            .withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Stats Column ────────────────────────────
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  // Prestasi
                  _StatCard(
                    icon: Icons.star,
                    iconColor: RekapTheme.primary,
                    label: 'PRESTASI',
                    value: '+${dp.achievementPoints} Poin',
                  ),
                  const SizedBox(height: 12),
                  // Pelanggaran
                  _StatCard(
                    icon: Icons.warning_amber,
                    iconColor: RekapTheme.error,
                    label: 'PELANGGARAN',
                    value: '-${dp.violationPoints} Poin',
                    valueColor: RekapTheme.error,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ranking Kelas
        Container(
          decoration: BoxDecoration(
            color: RekapTheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: RekapTheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RANKING KELAS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF426E47),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Peringkat ${dp.classRanking}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF426E47),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: 1 - (dp.classRanking / 32),
                  minHeight: 8,
                  backgroundColor: const Color(0xFF426E47).withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF426E47),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: RekapTheme.surfaceContainer),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: RekapTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: valueColor ?? RekapTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RekapTheme.surfaceContainer),
      ),
      child: Icon(icon, color: RekapTheme.primary, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RecordItem extends StatelessWidget {
  const _RecordItem({required this.record});
  final DisciplineRecord record;

  IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'schedule':
        return Icons.schedule;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'local_library':
        return Icons.local_library;
      case 'warning':
        return Icons.warning;
      case 'star':
        return Icons.star;
      case 'sports_soccer':
        return Icons.sports_soccer;
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = record.isPositive
        ? RekapTheme.tertiaryFixed
        : RekapTheme.errorContainer;
    final iconColor = record.isPositive
        ? const Color(0xFF002203)
        : const Color(0xFF93000A);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: RekapTheme.surfaceContainer),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(record.icon), color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RekapTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kategori ${record.category} • ${_formatDate(record.date)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: RekapTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.isPositive ? '+' : ''}${record.points}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: record.isPositive
                      ? RekapTheme.primary
                      : RekapTheme.error,
                ),
              ),
              Text(
                record.isPositive ? 'POIN PRESTASI' : 'POIN DISIPLIN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: record.isPositive
                      ? RekapTheme.primary
                      : RekapTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ViewMoreButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RekapTheme.outlineVariant,
          width: 2,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: const Center(
        child: Text(
          'Lihat Riwayat Lengkap',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: RekapTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RekapTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Icon(
              Icons.info_outline,
              color: RekapTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pahami Aturan Poin',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: RekapTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Baca buku saku digital untuk memahami kriteria poin.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: RekapTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: RekapTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Buka Panduan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
