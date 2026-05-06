import 'package:flutter/material.dart';

import '../data/rekap_repository.dart';
import '../models/school_news.dart';
import '../models/student.dart';
import '../theme/rekap_theme.dart';
import 'announcements_screen.dart';
import 'news_detail_screen.dart';

/// Beranda Orang Tua – Parent Home Screen
/// Matches: beranda-orang-tua-user.html
class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key, this.onRefresh});
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository.instance;
    final student = repo.childStudent;
    final news = repo.schoolNews;

    if (student == null) {
      return Scaffold(
        backgroundColor: RekapTheme.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search, size: 64, color: RekapTheme.outline),
              const SizedBox(height: 16),
              const Text('Belum ada data siswa', style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
              const SizedBox(height: 12),
              if (onRefresh != null)
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat Ulang'),
                  style: FilledButton.styleFrom(backgroundColor: RekapTheme.primary),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (onRefresh != null) {
              onRefresh!();
            } else {
              await repo.refresh();
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              // ── Welcome ─────────────────────────────────────
              Text(
                'Halo, Ibu/Bapak ${repo.currentUser.name.split(' ').first}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: RekapTheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pantau perkembangan akademik Ananda hari ini.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: RekapTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // ── Child Profile Card ──────────────────────────
              _ChildProfileCard(student: student),
              const SizedBox(height: 32),

              // ── Kabar Harian Sekolah ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kabar Harian Sekolah',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: RekapTheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AnnouncementsScreen(isAdmin: false),
                        ),
                      );
                    },
                    child: const Text(
                      'Lihat Semua',
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
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: news.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < news.length - 1 ? 16 : 0,
                      ),
                      child: SizedBox(
                        width: 280, // Fixed width for horizontal scrolling
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NewsDetailScreen(news: news[index]),
                              ),
                            );
                          },
                          child: _NewsCard(news: news[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Child Profile Card
// ─────────────────────────────────────────────────────────────────────────────
class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: RekapTheme.surfaceContainer),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Student info row
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: RekapTheme.primaryFixed,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    student.name.characters.first,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: RekapTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: RekapTheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelas ${student.className} • NISN: ${student.nisn}',
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
                Icons.chevron_right,
                color: RekapTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.assessment,
                  label: 'RATA-RATA NILAI',
                  value: student.averageScore.toStringAsFixed(1),
                  suffix: '/100',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.verified_user,
                  label: 'POIN KEDISIPLINAN',
                  value:
                      student.disciplinePoints.totalPoints.toString(),
                  suffix: 'Poin',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Attendance progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progres Kehadiran',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: RekapTheme.onSurface,
                    ),
                  ),
                  Text(
                    '${student.attendance.percentage.toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: RekapTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: student.attendance.percentage / 100,
                  minHeight: 8,
                  backgroundColor: RekapTheme.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    RekapTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
  });
  final IconData icon;
  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RekapTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: RekapTheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: RekapTheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: RekapTheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                suffix,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: RekapTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// News Card
// ─────────────────────────────────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news});
  final SchoolNews news;

  Color _categoryColor() {
    switch (news.category) {
      case NewsCategory.akademik:
        return RekapTheme.primary;
      case NewsCategory.pengumuman:
        return RekapTheme.tertiaryContainer;
      case NewsCategory.event:
        return RekapTheme.secondary;
      case NewsCategory.system:
        return RekapTheme.secondaryContainer;
    }
  }

  Color _categoryTextColor() {
    switch (news.category) {
      case NewsCategory.akademik:
        return Colors.white;
      case NewsCategory.pengumuman:
        return const Color(0xFFC8FFBF);
      case NewsCategory.event:
        return Colors.white;
      case NewsCategory.system:
        return RekapTheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: RekapTheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area with category badge
          Stack(
            children: [
              if (news.fullImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    news.fullImageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: RekapTheme.surfaceContainerLow,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _iconForCategory(),
                          size: 48,
                          color: RekapTheme.outline,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: RekapTheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _iconForCategory(),
                      size: 48,
                      color: RekapTheme.outline,
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryColor(),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    news.category.label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: _categoryTextColor(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  _formatDate(news.date),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: RekapTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: RekapTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    news.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: RekapTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory() {
    switch (news.category) {
      case NewsCategory.akademik:
        return Icons.science;
      case NewsCategory.pengumuman:
        return Icons.local_library;
      case NewsCategory.event:
        return Icons.celebration;
      case NewsCategory.system:
        return Icons.system_update;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
