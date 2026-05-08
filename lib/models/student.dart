/// Model class representing a student in the system.
class Student {
  const Student({
    this.id = 0,
    required this.name,
    required this.nisn,
    required this.className,
    required this.gradeLevel,
    required this.semester,
    required this.academicYear,
    required this.subjects,
    required this.disciplinePoints,
    required this.attendance,
    this.histories = const [],
    this.photoUrl,
  });

  final int id;
  final String name;
  final String nisn;
  final String className;
  final int gradeLevel;
  final String semester;
  final String academicYear;
  final List<SubjectScore> subjects;
  final DisciplinePoints disciplinePoints;
  final AttendanceData attendance;
  final List<StudentHistory> histories;
  final String? photoUrl;

  String get currentPeriod => 'Kelas $gradeLevel Semester $semester';

  double get averageScore {
    final scores = subjects.map((s) => s.score).whereType<double>().toList();
    if (scores.isEmpty) return 0;
    final total = scores.reduce((a, b) => a + b);
    return total / scores.length;
  }

  String get academicStatus {
    final avg = averageScore;
    if (avg >= 90) return 'TOP TIER';
    if (avg >= 85) return 'EXCELLENT';
    if (avg >= 80) return 'ABOVE AVG';
    if (avg >= 75) return 'STABLE';
    return 'NEEDS IMPROVEMENT';
  }

  Student copyWith({
    int? id,
    String? name,
    String? nisn,
    String? className,
    int? gradeLevel,
    String? semester,
    String? academicYear,
    List<SubjectScore>? subjects,
    DisciplinePoints? disciplinePoints,
    AttendanceData? attendance,
    List<StudentHistory>? histories,
    String? photoUrl,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      nisn: nisn ?? this.nisn,
      className: className ?? this.className,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      subjects: subjects ?? this.subjects,
      disciplinePoints: disciplinePoints ?? this.disciplinePoints,
      attendance: attendance ?? this.attendance,
      histories: histories ?? this.histories,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class StudentHistory {
  const StudentHistory({
    required this.id,
    required this.className,
    required this.gradeLevel,
    required this.semester,
    required this.academicYear,
  });

  final int id;
  final String className;
  final int gradeLevel;
  final String semester;
  final String academicYear;

  String get period => 'Kelas $gradeLevel Semester $semester';
}

class ScoreDetail {
  const ScoreDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.score,
    this.date,
  });

  final int id;
  final String name; // e.g. Tugas 1
  final String type; // e.g. tugas, uts, uas
  final double score;
  final DateTime? date;
}

/// Model class representing a score in a specific subject.
class SubjectScore {
  const SubjectScore({
    this.id = 0,
    required this.subjectId,
    required this.gradeLevel,
    required this.name,
    required this.score,
    required this.teacher,
    required this.icon,
    this.details = const [],
  });

  final int id;
  final int subjectId;
  final int gradeLevel;
  final String name;
  final double? score;
  final String teacher;
  final String icon; // Material icon name
  final List<ScoreDetail> details;

  bool get isPassing => (score ?? 0) >= 75;
  String get status => isPassing ? 'LULUS' : 'PERBAIKAN';

  SubjectScore copyWith({
    double? score,
    int? gradeLevel,
    List<ScoreDetail>? details,
  }) {
    return SubjectScore(
      id: id,
      subjectId: subjectId,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      name: name,
      score: score ?? this.score,
      teacher: teacher,
      icon: icon,
      details: details ?? this.details,
    );
  }
}

/// Model class representing discipline points breakdown.
class DisciplinePoints {
  const DisciplinePoints({
    required this.totalPoints,
    required this.achievementPoints,
    required this.violationPoints,
    required this.classRanking,
    required this.records,
  });

  final int totalPoints;
  final int achievementPoints;
  final int violationPoints;
  final int classRanking;
  final List<DisciplineRecord> records;

  String get predicate {
    if (totalPoints >= 200) return 'Sangat Baik';
    if (totalPoints >= 150) return 'Baik';
    if (totalPoints >= 100) return 'Cukup';
    return 'Kurang';
  }
}

/// Model class representing a single discipline record entry.
class DisciplineRecord {
  const DisciplineRecord({
    required this.title,
    required this.category,
    required this.date,
    required this.points,
    required this.icon,
  });

  final String title;
  final String category;
  final DateTime date;
  final int points; // positive = achievement, negative = violation
  final String icon; // Material icon name

  bool get isPositive => points > 0;
}

/// Model class representing attendance data.
class AttendanceData {
  const AttendanceData({
    required this.percentage,
    required this.izin,
    required this.sakit,
    required this.alfa,
  });

  final double percentage;
  final int izin;
  final int sakit;
  final int alfa;

  String get status {
    if (percentage >= 95) return 'Sangat Baik';
    if (percentage >= 85) return 'Baik';
    if (percentage >= 75) return 'Cukup';
    return 'Kurang';
  }
}

