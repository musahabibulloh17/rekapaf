import 'dart:async';
import 'dart:io';

import '../models/student.dart';
import '../models/classroom.dart';
import '../models/subject.dart';
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
  List<Classroom> _classrooms = [];
  List<Subject> _subjects = [];
  Map<int, List<String>> _subjectTeachers = {};
  bool _isLoading = false;

  List<Student> get students => List.unmodifiable(_students);
  List<SchoolNews> get schoolNews => List.unmodifiable(_schoolNews);
  List<Classroom> get classrooms => List.unmodifiable(_classrooms);
  List<Subject> get subjects => List.unmodifiable(_subjects);
  bool get isLoading => _isLoading;

  // ── Current User (delegates to AuthService) ───────────────────────────
  UserProfile get currentUser =>
      AuthService.instance.currentUser ??
      const UserProfile(name: 'Guest', role: UserRole.parent);

  // ── Load All Data ─────────────────────────────────────────────────────

  Future<void> loadAll() async {
    _isLoading = true;
    await loadTeacherAssignments();
    await Future.wait([
      loadStudents(),
      loadNews(),
      loadClassrooms(),
      loadSubjects(),
    ]);
    _isLoading = false;
  }

  Future<void> refresh() => loadAll();

  // ── Classrooms ───────────────────────────────────────────────────────

  Future<void> loadClassrooms() async {
    try {
      final response = await ApiService.get('/classrooms');
      if (response['success'] == true) {
        final list = response['data'] as List;
        _classrooms = list.map((json) => Classroom.fromJson(json)).toList();
      }
    } catch (_) {}
  }

  Future<void> loadSubjects() async {
    try {
      final response = await ApiService.get('/subjects');
      if (response['success'] == true) {
        final list = response['data'] as List;
        _subjects = list.map((json) => Subject.fromJson(json)).toList();
      }
    } catch (_) {}
  }

  // ── Students ──────────────────────────────────────────────────────────

  Future<void> loadStudents() async {
    try {
      if (_subjectTeachers.isEmpty) {
        await loadTeacherAssignments();
      }
      final endpoint = currentUser.isGuru || currentUser.isWaliKelas
          ? '/teacher/students'
          : '/students';
      final response = await ApiService.get(endpoint);
      if (response['success'] == true) {
        final list = response['data'] as List;
        _students = list.map((json) => _parseStudent(json)).toList();
      }
    } catch (e) {
      // Keep cached data if API fails
    }
  }

  Future<void> updateScoreDetail({
    required int detailId,
    required String name,
    required String type,
    required double score,
    DateTime? date,
  }) async {
    try {
      await ApiService.put('/scores/details/$detailId', {
        'name': name,
        'type': type,
        'score': score,
        'date': date?.toIso8601String().split('T')[0],
      });
    } catch (e) {
      throw 'Gagal memperbarui nilai: $e';
    }
  }

  Future<void> deleteScoreDetail(int detailId) async {
    try {
      await ApiService.delete('/scores/details/$detailId');
    } catch (e) {
      throw 'Gagal menghapus nilai: $e';
    }
  }

  Future<void> loadTeacherAssignments() async {
    try {
      final response = await ApiService.get('/accounts');
      if (response['success'] == true) {
        final list = response['data'] as List? ?? [];
        final Map<int, Set<String>> grouped = {};

        for (final account in list) {
          if (account is! Map<String, dynamic>) continue;
          final role = account['role'];
          if (role != 'guru' && role != 'wali_kelas') continue;
          final name = (account['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;

          final subjects = account['subjects'] as List? ?? [];
          for (final subject in subjects) {
            if (subject is! Map<String, dynamic>) continue;
            final id = subject['id'] as int?;
            if (id == null) continue;
            grouped.putIfAbsent(id, () => <String>{}).add(name);
          }
        }

        _subjectTeachers = grouped.map(
          (key, value) => MapEntry(key, value.toList()..sort()),
        );
      }
    } catch (_) {
      // Ignore teacher assignment errors to avoid blocking student data.
    }
  }

  Future<Student?> getStudentById(
    int id, {
    int? gradeLevel,
    String? semester,
    String? academicYear,
  }) async {
    try {
      String path = '/students/$id';
      final Map<String, String> queryParams = {};
      if (gradeLevel != null)
        queryParams['grade_level'] = gradeLevel.toString();
      if (semester != null) queryParams['semester'] = semester;
      if (academicYear != null) queryParams['academic_year'] = academicYear;

      if (queryParams.isNotEmpty) {
        path += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await ApiService.get(path);
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
    if (currentUser.isGuru || currentUser.isWaliKelas) {
      return _students
          .where(
            (s) =>
                s.name.toLowerCase().contains(query.toLowerCase()) ||
                s.nisn.contains(query),
          )
          .toList();
    }

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
    double focalX = 0.0,
    double focalY = 0.0,
  }) async {
    await ApiService.postMultipart(
      '/news',
      {
        'title': title,
        'description': description,
        'category': category,
        'news_date': date,
        'focal_x': focalX.toString(),
        'focal_y': focalY.toString(),
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
    double focalX = 0.0,
    double focalY = 0.0,
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
        'focal_x': focalX.toString(),
        'focal_y': focalY.toString(),
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
    int? gradeLevel,
    String? semester,
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
    // Allow superadmin to input grades for previous semesters
    if (gradeLevel != null) {
      body['grade_level'] = gradeLevel;
    }
    if (semester != null) {
      body['semester'] = semester;
    }

    await ApiService.post('/scores/details', body);
    await loadStudents();
  }

  Future<void> importAllSubjectsScores({
    required int studentId,
    required File file,
    required int gradeLevel,
    required String semester,
    required String academicYear,
  }) async {
    await ApiService.postMultipart(
      '/scores/import/all/$studentId',
      {
        'grade_level': gradeLevel.toString(),
        'semester': semester,
        'academic_year': academicYear,
      },
      file,
      'file',
    );
    await loadStudents();
  }

  Future<void> importSubjectDetails({
    required int studentId,
    required int subjectId,
    required File file,
    required int gradeLevel,
    required String semester,
    required String academicYear,
  }) async {
    await ApiService.postMultipart(
      '/scores/import/subject/$studentId/$subjectId',
      {
        'grade_level': gradeLevel.toString(),
        'semester': semester,
        'academic_year': academicYear,
      },
      file,
      'file',
    );
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
    final subjects =
        (json['subjects'] as List?)?.map((s) {
          final details =
              (s['details'] as List?)?.map((d) {
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
            gradeLevel: s['grade_level'] ?? 12,
            name: s['name'] ?? '',
            score: s['score'] != null ? (s['score'] as num).toDouble() : null,
            teacher: _subjectTeachers[s['subject_id'] ?? 0]?.isNotEmpty == true
                ? _subjectTeachers[s['subject_id'] ?? 0]!.join(' & ')
                : s['teacher'] ?? '-',
            icon: s['icon'] ?? 'book',
            details: details,
          );
        }).toList() ??
        [];

    final dpData = json['discipline_points'] as Map<String, dynamic>?;
    final records =
        (dpData?['records'] as List?)?.map((r) {
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

    final histories =
        (json['histories'] as List?)?.map((h) {
          return StudentHistory(
            id: h['id'] ?? 0,
            className: h['class_name'] ?? '',
            gradeLevel: h['grade_level'] ?? 0,
            semester: h['semester'] ?? '',
            academicYear: h['academic_year'] ?? '',
          );
        }).toList() ??
        [];

    return Student(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nisn: json['nisn'] ?? '',
      className: json['class_name'] ?? '',
      gradeLevel: json['grade_level'] ?? 12,
      semester: json['semester'] ?? 'Ganjil',
      academicYear: json['academic_year'] ?? '',
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
      histories: histories,
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
      date: (DateTime.tryParse(json['updated_at'] ?? json['created_at'] ?? json['news_date'] ?? '') ?? DateTime.now()).toLocal(),
      category: category,
      imageUrl: json['image_url'],
      focalX: (json['focal_x'] as num?)?.toDouble() ?? 0.0,
      focalY: (json['focal_y'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
