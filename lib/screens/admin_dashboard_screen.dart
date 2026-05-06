import 'package:flutter/material.dart';

import '../data/rekap_repository.dart';
import '../models/school_news.dart';
import '../models/user_profile.dart';
import '../theme/rekap_theme.dart';
import 'announcements_screen.dart';
import 'news_detail_screen.dart';

/// Dashboard Wali Kelas – Admin Home Screen
/// Matches: dashboard-wali-kelas-admin.html
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, this.onRefresh});
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository.instance;
    final user = repo.currentUser;

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
              // ── Welcome Section ─────────────────────────────
              Text(
                'Selamat Pagi, ${user.name}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: RekapTheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  List<String> roles = [];
                  if (user.isSuperAdmin) {
                    roles.add("Super Admin");
                  } else {
                    if (user.isGuru) roles.add("Guru Mata Pelajaran");
                    if (user.isWaliKelas) {
                      roles.add("Wali Kelas ${user.homeroomClassName ?? ''}");
                    }
                    if (user.role == UserRole.parent) roles.add("Orang Tua");
                  }
                  return Text(
                    'Role: ${roles.join(" & ")}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: RekapTheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Summary Cards ───────────────────────────────
              _SummaryCards(repo: repo),
              const SizedBox(height: 28),

              // ── Quick Access ────────────────────────────────
              const Text(
                'Quick Access',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: RekapTheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              _QuickAccessGrid(isGuru: !user.isAdmin),
              const SizedBox(height: 28),

              // ── Pengumuman Sekolah ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pengumuman Sekolah',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: RekapTheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AnnouncementsScreen(isAdmin: user.isAdmin),
                        ),
                      );
                    },
                    child: Text(
                      user.isAdmin ? 'Manage' : 'Lihat Semua',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: RekapTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(height: 260, child: _NewsCarousel(news: repo.schoolNews)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.repo});
  final RekapRepository repo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.group,
                iconBgColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                iconColor: RekapTheme.primary,
                badge: '+2 New',
                badgeBgColor: RekapTheme.primaryFixed,
                badgeColor: RekapTheme.primary,
                label: 'TOTAL SISWA',
                value: repo.totalStudents.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.assessment,
                iconBgColor: RekapTheme.tertiaryContainer.withValues(
                  alpha: 0.1,
                ),
                iconColor: RekapTheme.tertiary,
                badge: 'Top 5%',
                badgeBgColor: RekapTheme.tertiaryFixed,
                badgeColor: RekapTheme.tertiary,
                label: 'RATA-RATA KELAS',
                value: repo.classAverage.toStringAsFixed(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          icon: Icons.gavel,
          iconBgColor: RekapTheme.errorContainer.withValues(alpha: 0.2),
          iconColor: RekapTheme.error,
          badge: 'Urgent',
          badgeBgColor: RekapTheme.errorContainer,
          badgeColor: RekapTheme.error,
          label: 'PELANGGARAN HARI INI',
          value: repo.students
              .expand((s) => s.disciplinePoints.records)
              .where((r) {
                final today = DateTime.now();
                return r.date.year == today.year &&
                    r.date.month == today.month &&
                    r.date.day == today.day &&
                    r.points < 0;
              })
              .length
              .toString(),
          fullWidth: true,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.badge,
    required this.badgeBgColor,
    required this.badgeColor,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String badge;
  final Color badgeBgColor;
  final Color badgeColor;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.transparent),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: RekapTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({this.isGuru = false});
  final bool isGuru;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _QuickAccessItem(
          icon: Icons.person_search,
          label: 'Student List',
          isPrimary: true,
          onTap: () {
            // Navigator to student list tab is handled by main.dart indexing
          },
        ),
        _QuickAccessItem(
          icon: Icons.edit_note,
          label: 'Input Grades',
          isPrimary: false,
          onTap: () {
            // Navigator to student list tab
          },
        ),
        if (!isGuru)
          _QuickAccessItem(
            icon: Icons.calendar_month,
            label: 'Attendance',
            isPrimary: false,
            onTap: () {},
          ),
        _QuickAccessItem(
          icon: Icons.newspaper,
          label: 'Announcements',
          isPrimary: false,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnnouncementsScreen(isAdmin: !isGuru),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? RekapTheme.primaryContainer : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isPrimary
                ? null
                : Border.all(color: RekapTheme.outlineVariant),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: RekapTheme.primaryContainer.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isPrimary ? Colors.white : RekapTheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isPrimary ? Colors.white : RekapTheme.onSurface,
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
class _NewsCarousel extends StatelessWidget {
  const _NewsCarousel({required this.news});
  final List<SchoolNews> news;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: news.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(right: index < news.length - 1 ? 12 : 0),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewsDetailScreen(news: news[index]),
                ),
              );
            },
            child: _NewsCardSmall(news: news[index]),
          ),
        );
      },
    );
  }
}

class _NewsCardSmall extends StatelessWidget {
  const _NewsCardSmall({required this.news});
  final SchoolNews news;

  Color _categoryColor() {
    switch (news.category) {
      case NewsCategory.akademik:
        return RekapTheme.primaryFixed;
      case NewsCategory.event:
        return RekapTheme.tertiaryFixed;
      case NewsCategory.system:
        return RekapTheme.secondaryContainer;
      case NewsCategory.pengumuman:
        return RekapTheme.secondaryContainer;
    }
  }

  Color _categoryTextColor() {
    switch (news.category) {
      case NewsCategory.akademik:
        return RekapTheme.primary;
      case NewsCategory.event:
        return RekapTheme.tertiary;
      case NewsCategory.system:
        return const Color(0xFF426E47);
      case NewsCategory.pengumuman:
        return RekapTheme.secondary;
    }
  }

  IconData _categoryIcon() {
    switch (news.category) {
      case NewsCategory.akademik:
        return Icons.school;
      case NewsCategory.event:
        return Icons.celebration;
      case NewsCategory.system:
        return Icons.system_update;
      case NewsCategory.pengumuman:
        return Icons.campaign;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.fullImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                news.fullImageUrl,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: RekapTheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Center(
                    child: Icon(_categoryIcon(), size: 36, color: RekapTheme.outline),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: RekapTheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Icon(_categoryIcon(), size: 36, color: RekapTheme.outline),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    news.category.label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: _categoryTextColor(),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: RekapTheme.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  news.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: RekapTheme.onSurfaceVariant,
                    height: 1.4,
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
