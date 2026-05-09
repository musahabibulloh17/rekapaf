import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/school_news.dart';
import '../data/rekap_repository.dart';
import 'add_announcement_screen.dart';
import 'news_detail_screen.dart';
import '../widgets/loading_indicator.dart';
import '../theme/rekap_theme.dart';

/// Screen untuk menampilkan daftar pengumuman
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late NewsCategory? _selectedFilter;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = null;
    _refreshNews();
  }

  Future<void> _refreshNews() async {
    setState(() => _isLoading = true);
    await RekapRepository.instance.loadNews();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = RekapRepository.instance;
    final announcements = repo.schoolNews;
    final filtered = _selectedFilter == null
        ? announcements
        : announcements
              .where((a) => a.category == _selectedFilter)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman Sekolah'),
        actions: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Tooltip(
                  message: 'Tambah pengumuman',
                  child: IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddAnnouncementScreen(),
                        ),
                      );
                      _refreshNews();
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : Column(
              children: [
              /// Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: _selectedFilter == null,
                      selectedColor: RekapTheme.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight:
                            _selectedFilter == null
                                ? FontWeight.w700
                                : FontWeight.w500,
                        color:
                            _selectedFilter == null
                                ? Colors.white
                                : RekapTheme.onSurfaceVariant,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ...NewsCategory.values.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.label),
                          selected: _selectedFilter == category,
                          selectedColor: RekapTheme.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight:
                                _selectedFilter == category
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                            color:
                                _selectedFilter == category
                                    ? Colors.white
                                    : RekapTheme.onSurfaceVariant,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedFilter =
                                  _selectedFilter == category ? null : category;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              /// Announcements list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada pengumuman',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final announcement = filtered[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => NewsDetailScreen(news: announcement),
                                ),
                              );
                            },
                            child: _AnnouncementCard(
                              announcement: announcement,
                              isAdmin: widget.isAdmin,
                            onEdit: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddAnnouncementScreen(
                                    announcement: announcement,
                                  ),
                                ),
                              );
                              _refreshNews();
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Pengumuman?'),
                                  content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Batal'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await repo.deleteNews(announcement.id);
                                _refreshNews();
                              }
                            },
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  final SchoolNews announcement;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(announcement.category.label),
                        backgroundColor: _getCategoryColor(
                          announcement.category,
                        ).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: _getCategoryColor(announcement.category),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(child: const Text('Edit'), onTap: onEdit),
                      PopupMenuItem(
                        child: const Text('Hapus'),
                        onTap: onDelete,
                      ),
                    ],
                  ),
              ],
            ),
            if (announcement.fullImageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  announcement.fullImageUrl,
                  height: 160,
                  width: double.infinity,
                  alignment: Alignment(announcement.focalX, announcement.focalY),
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 160,
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              announcement.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              dateFormat.format(announcement.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(NewsCategory category) {
    switch (category) {
      case NewsCategory.akademik:
        return const Color(0xFF0D631B);
      case NewsCategory.pengumuman:
        return const Color(0xFF1F6223);
      case NewsCategory.event:
        return const Color(0xFF2E7D32);
      case NewsCategory.system:
        return const Color(0xFF707A6C);
    }
  }
}
