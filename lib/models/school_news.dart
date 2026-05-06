import '../services/api_service.dart';

/// Model class representing a school news/announcement item.
class SchoolNews {
  const SchoolNews({
    this.id = 0,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    required this.imageUrl,
  });

  final int id;
  final String title;
  final String description;
  final DateTime date;
  final NewsCategory category;
  final String? imageUrl;

  String get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return '';
    if (imageUrl!.startsWith('http')) return imageUrl!;
    final baseUrl = ApiService.currentBaseUrl.replaceAll('/api', '');
    return '$baseUrl/storage/$imageUrl';
  }
}

/// Enum representing the category of a school news item.
enum NewsCategory {
  akademik('Akademik'),
  pengumuman('Pengumuman'),
  event('Event'),
  system('System');

  const NewsCategory(this.label);
  final String label;
}
