import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/school_news.dart';
import '../theme/rekap_theme.dart';
import '../services/api_service.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.news});
  
  final SchoolNews news;

  String _getImageUrl() {
    if (news.imageUrl == null || news.imageUrl!.isEmpty) {
      return '';
    }
    if (news.imageUrl!.startsWith('http')) {
      return news.imageUrl!;
    }
    // Assume relative path from storage
    final baseUrl = ApiService.currentBaseUrl.replaceAll('/api', '');
    return '$baseUrl/storage/${news.imageUrl}';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');
    final imageUrl = _getImageUrl();

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        backgroundColor: Colors.white,
        foregroundColor: RekapTheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 2.0,
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      alignment: Alignment(news.focalX, news.focalY),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: RekapTheme.surfaceContainerLow,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48, color: RekapTheme.outline),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _FullImageViewer(imageUrl: imageUrl),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              AspectRatio(
                aspectRatio: 2.0,
                child: Container(
                  width: double.infinity,
                  color: RekapTheme.surfaceContainerLow,
                  child: Center(
                    child: Icon(
                      _iconForCategory(news.category),
                      size: 64,
                      color: RekapTheme.outline,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _categoryColor(news.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      news.category.label.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _categoryColor(news.category),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: RekapTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: RekapTheme.outline),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(news.date),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: RekapTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    news.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      height: 1.6,
                      color: RekapTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(NewsCategory category) {
    switch (category) {
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

  Color _categoryColor(NewsCategory category) {
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

class _FullImageViewer extends StatelessWidget {
  final String imageUrl;
  const _FullImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.network(
                imageUrl,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
