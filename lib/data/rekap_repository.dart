import 'dart:async';
import 'dart:io';

import '../models/student.dart';
import '../models/school_news.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Repository providing all data for the app via Laravel API.
/// No more dummy data — everything comes from the backend.
class RekapRepository {
  RekapRepository._();
  static final RekapRepository instance = RekapRepository._();

  // ── Cached Data ───────────────────────────────────────────────────────
  List<Student> _students = [];
  List<SchoolNews> _schoolNews = [];
  bool _isLoading = false;

  List<Student> get students => List.unmodifiable(_students);
  List<SchoolNews> get schoolNews => List.unmodifiable(_schoolNews);
  bool get isLoading => _isLoading;

  // ── Current User (delegates to AuthService) ───────────────────────────
  UserProfile get currentUser =>
      AuthService.instance.currentUser ??
      const UserProfile(name: 'Guest', role: UserRole.parent);

  // ── Load All Data ─────────────────────────────────────────────────────

  Future<void> loadAll() async {
    _isLoading = true;
    await Future.wait([loadStudents(), loadNews()]);
    _isLoading = false;
  }

  Future<void> refresh() => loadAll();

  // ── Students ──────────────────────────────────────────────────────────

  Future<void> loadStudents() async {
    try {
      final endpoint = currentUser.isGuru ? '/teacher/students' : '/students';
      final response = await ApiService.get(endpoint);
      if (response['success'] == true) {
        final list = response['data'] as List;
        _students = list.map((json) => _parseStudent(json)).toList();
      }
    } catch (e) {
      // Keep cached data if API fails
    }
  }

  Future<Student?> getStudentById(int id) async {
    try {
      final response = await ApiService.get('/students/$id');
      if (response['success'] == true) {
        return _parseStudent(response['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<Student?> getStudentByNisn(String nisn) async {
    try {
      final response = await ApiService.get('/students/nisn/$nisn');
      if (response['success'] == true) {
        return _parseStudent(response['data']);
      }
    } catch (_) {}
    return null;
  }

  /// Returns the child student for the current parent user.
  Student? get childStudent {
    final childId = currentUser.childStudentId;
    if (childId == null) return _students.isNotEmpty ? _students.first : null;
    try {
      return _students.firstWhere(
        (s) => s.nisn == childId || s.id.toString() == childId,
      );
    } catch (_) {
      return _students.isNotEmpty ? _students.first : null;
    }
  }

  /// Search students by name or NISN.
  Future<List<Student>> searchStudents(String query) async {
    try {
      final response = await ApiService.get('/students?search=$query');
      if (response['success'] == true) {
        final list = response['data'] as List;
        return list.map((json) => _parseStudent(json)).toList();
      }
    } catch (_) {}
    // Fallback to local filter
    return _students
        .where(
          (s) =>
              s.name.toLowerCase().contains(query.toLowerCase()) ||
              s.nisn.contains(query),
        )
        .toList();
  }

  // ── Class Summary (Admin) ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getClassSummary() async {
    try {
      final response = await ApiService.get('/class-summary');
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'total_students': _students.length,
      'class_average': 0.0,
      'today_violations': 0,
      'top_student': null,
    };
  }

  double get classAverage {
    if (_students.isEmpty) return 0;
    final total = _students.map((s) => s.averageScore).reduce((a, b) => a + b);
    return total / _students.length;
  }

  int get totalStudents => _students.length;

  // ── School News ───────────────────────────────────────────────────────

  Future<void> loadNews() async {
    try {
      final response = await ApiService.get('/news');
      if (response['success'] == true) {
        final list = response['data'] as List;
        _schoolNews = list.map((json) => _parseNews(json)).toList();
      }
    } catch (_) {}
  }

  Future<void> addNews({
    required String title,
    required String description,
    required String category,
    required String date,
    File? imageFile,
  }) async {
    await ApiService.postMultipart(
      '/news',
      {
        'title': title,
        'description': description,
        'category': category,
        'news_date': date,
      },
      imageFile,
      'image',
    );
    await loadNews();
  }

  Future<void> updateNews({
    required int id,
    required String title,
    required String description,
    required String category,
    required String date,
    File? imageFile,
  }) async {
    // Note: Laravel PUT requests with multipart/form-data can be tricky.
    // Usually, we send POST and include _method=PUT in fields.
    await ApiService.postMultipart(
      '/news/$id',
      {
        '_method': 'PUT',
        'title': title,
        'description': description,
        'category': category,
        'news_date': date,
      },
      imageFile,
      'image',
    );
    await loadNews();
  }

  Future<void> deleteNews(int id) async {
    await ApiService.delete('/news/$id');
    await loadNews();
  }

  // ── Scores ────────────────────────────────────────────────────────────

  Future<void> updateScore(int scoreId, double newScore) async {
    await ApiService.put('/scores/$scoreId', {'score': newScore});
    await loadStudents(); // Refresh
  }

  Future<void> addScoreDetail({
    required int studentId,
    required int subjectId,
    required String name,
    required String type,
    required double score,
    String? date,
  }) async {
    final Map<String, dynamic> body = {
      'student_id': studentId,
      'subject_id': subjectId,
      'name': name,
      'type': type,
      'score': score,
    };
    if (date != null && date.isNotEmpty) {
      body['date'] = date;
    }

    await ApiService.post('/scores/details', body);
    await loadStudents();
  }

  // ── Discipline ────────────────────────────────────────────────────────

  Future<void> addDisciplineRecord({
    required int studentId,
    required String title,
    required String category,
    required String date,
    required int points,
    String icon = 'flag',
  }) async {
    await ApiService.post('/discipline', {
      'student_id': studentId,
      'title': title,
      'category': category,
      'record_date': date,
      'points': points,
      'icon': icon,
    });
    await loadStudents(); // Refresh
  }

  // ── Parsers ───────────────────────────────────────────────────────────

  Student _parseStudent(Map<String, dynamic> json) {
    final subjects = (json['subjects'] as List?)?.map((s) {
          final details = (s['details'] as List?)?.map((d) {
                return ScoreDetail(
                  id: d['id'] ?? 0,
                  name: d['name'] ?? '',
                  type: d['type'] ?? 'tugas',
                  score: (d['score'] as num?)?.toDouble() ?? 0,
                  date: DateTime.tryParse(d['date'] ?? ''),
                );
              }).toList() ??
              [];
          return SubjectScore(
            id: s['id'] ?? 0,
            subjectId: s['subject_id'] ?? 0,
            name: s['name'] ?? '',
            score: (s['score'] as num?)?.toDouble() ?? 0,
            teacher: s['teacher'] ?? '-',
            icon: s['icon'] ?? 'book',
            details: details,
          );
        }).toList() ??
        [];

    final dpData = json['discipline_points'] as Map<String, dynamic>?;
    final records = (dpData?['records'] as List?)?.map((r) {
          return DisciplineRecord(
            title: r['title'] ?? '',
            category: r['category'] ?? '',
            date: DateTime.tryParse(r['date'] ?? '') ?? DateTime.now(),
            points: r['points'] ?? 0,
            icon: r['icon'] ?? 'flag',
          );
        }).toList() ??
        [];

    final attData = json['attendance'] as Map<String, dynamic>?;

    return Student(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nisn: json['nisn'] ?? '',
      className: json['class_name'] ?? '',
      photoUrl: json['photo_url'],
      subjects: subjects,
      disciplinePoints: DisciplinePoints(
        totalPoints: dpData?['total_points'] ?? 0,
        achievementPoints: dpData?['achievement_points'] ?? 0,
        violationPoints: dpData?['violation_points'] ?? 0,
        classRanking: 0,
        records: records,
      ),
      attendance: AttendanceData(
        percentage: (attData?['percentage'] as num?)?.toDouble() ?? 0,
        izin: attData?['izin'] ?? 0,
        sakit: attData?['sakit'] ?? 0,
        alfa: attData?['alfa'] ?? 0,
      ),
    );
  }

  SchoolNews _parseNews(Map<String, dynamic> json) {
    NewsCategory category;
    switch (json['category']) {
      case 'akademik':
        category = NewsCategory.akademik;
        break;
      case 'pengumuman':
        category = NewsCategory.pengumuman;
        break;
      case 'event':
        category = NewsCategory.event;
        break;
      case 'system':
        category = NewsCategory.system;
        break;
      default:
        category = NewsCategory.pengumuman;
    }

    return SchoolNews(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['news_date'] ?? '') ?? DateTime.now(),
      category: category,
      imageUrl: json['image_url'],
    );
  }
}
