import 'dart:async';

import '../models/school_news.dart';

/// Service untuk mengelola pengumuman sekolah
class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();

  factory AnnouncementService() {
    return _instance;
  }

  AnnouncementService._internal();

  final List<SchoolNews> _announcements = [
    SchoolNews(
      title: 'Libur Semester Genap',
      description:
          'Libur semester genap dimulai dari tanggal 15 Juni hingga 31 Agustus 2024.',
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: NewsCategory.pengumuman,
      imageUrl: null,
    ),
    SchoolNews(
      title: 'Acara Perpisahan Kelas XII',
      description:
          'Acara perpisahan kelas XII akan diadakan pada tanggal 8 Juni 2024 pukul 09.00 WIB di aula sekolah.',
      date: DateTime.now().subtract(const Duration(days: 7)),
      category: NewsCategory.event,
      imageUrl: null,
    ),
  ];

  final _announcementsController =
      StreamController<List<SchoolNews>>.broadcast();

  Stream<List<SchoolNews>> get announcementsStream =>
      _announcementsController.stream;

  List<SchoolNews> get announcements => List.unmodifiable(_announcements);

  /// Tambah pengumuman baru
  void addAnnouncement(SchoolNews announcement) {
    _announcements.insert(0, announcement);
    _announcementsController.add(announcements);
  }

  /// Update pengumuman
  void updateAnnouncement(int index, SchoolNews announcement) {
    if (index >= 0 && index < _announcements.length) {
      _announcements[index] = announcement;
      _announcementsController.add(announcements);
    }
  }

  /// Hapus pengumuman
  void deleteAnnouncement(int index) {
    if (index >= 0 && index < _announcements.length) {
      _announcements.removeAt(index);
      _announcementsController.add(announcements);
    }
  }

  /// Dapatkan pengumuman berdasarkan kategori
  List<SchoolNews> getAnnouncementsByCategory(NewsCategory category) {
    return _announcements.where((a) => a.category == category).toList();
  }

  void dispose() {
    _announcementsController.close();
  }
}
