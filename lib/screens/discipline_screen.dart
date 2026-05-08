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
              Icon(
                Icons.verified_user_outlined,
                size: 64,
                color: RekapTheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada data tatib',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16),
              ),
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
            const SizedBox(height: 24),

            // ── Masa Akademik Section ───────────────────────
            _AcademicStatusCard(student: student),
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
            const SizedBox(height: 32),

            // ── Jejak History Section ───────────────────────
            if (student.histories.isNotEmpty) ...[
              const Text(
                'Jejak History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: RekapTheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              ...student.histories.map(
                (history) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryItem(history: history),
                ),
              ),
            ],
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Points Card ─────────────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        RekapTheme.primaryContainer,
                        Color(0xFF1B5E20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: RekapTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'TOTAL POIN TATIB',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: RekapTheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dp.totalPoints.toString(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: RekapTheme.onPrimaryContainer,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: RekapTheme.onPrimaryContainer.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: RekapTheme.onPrimaryContainer.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            child: Text(
                              'Predikat: ${dp.predicate}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: RekapTheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Icon(
                          Icons.verified_user,
                          size: 140,
                          color: RekapTheme.onPrimaryContainer.withValues(
                            alpha: 0.1,
                          ),
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
                    Expanded(
                      child: _StatCard(
                        icon: Icons.stars_rounded,
                        iconColor: RekapTheme.primary,
                        label: 'PRESTASI',
                        value: '+${dp.achievementPoints} Poin',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Pelanggaran
                    Expanded(
                      child: _StatCard(
                        icon: Icons.report_problem_rounded,
                        iconColor: RekapTheme.error,
                        label: 'PELANGGARAN',
                        value: '-${dp.violationPoints} Poin',
                        valueColor: RekapTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Ranking Kelas
        Container(
          decoration: BoxDecoration(
            color: RekapTheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: RekapTheme.secondaryContainer.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.leaderboard_rounded,
                    size: 18,
                    color: Color(0xFF2E7D32),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'RANKING KELAS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Peringkat ${dp.classRanking}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: RekapTheme.onSurface,
                    ),
                  ),
                  Text(
                    'dari 32 Siswa',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: RekapTheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: 1 - (dp.classRanking / 32),
                  minHeight: 10,
                  backgroundColor: const Color(0xFF2E7D32).withValues(
                    alpha: 0.1,
                  ),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2E7D32),
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: RekapTheme.surfaceContainerLow),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: RekapTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor ?? RekapTheme.onSurface,
              ),
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
                record.isPositive ? 'POIN PRESTASI' : 'POIN TATIB',
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
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

// ─────────────────────────────────────────────────────────────────────────────
class _AcademicStatusCard extends StatelessWidget {
  const _AcademicStatusCard({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            RekapTheme.primary.withValues(alpha: 0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RekapTheme.primary.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RekapTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: RekapTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MASA AKADEMIK SAAT INI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: RekapTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.currentPeriod,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: RekapTheme.onSurface,
                  ),
                ),
                if (student.academicYear.isNotEmpty)
                  Text(
                    'Tahun Ajaran ${student.academicYear}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: RekapTheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: RekapTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'AKTIF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.history});
  final StudentHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RekapTheme.surfaceContainer),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: RekapTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: RekapTheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.period,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RekapTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelas ${history.className} • T.A ${history.academicYear}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: RekapTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: RekapTheme.outline,
          ),
        ],
      ),
    );
  }
}
