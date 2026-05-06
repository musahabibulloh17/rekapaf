/// Model class representing a student in the system.
class Student {
  const Student({
    this.id = 0,
    required this.name,
    required this.nisn,
    required this.className,
    required this.subjects,
    required this.disciplinePoints,
    required this.attendance,
    this.photoUrl,
  });

  final int id;
  final String name;
  final String nisn;
  final String className;
  final List<SubjectScore> subjects;
  final DisciplinePoints disciplinePoints;
  final AttendanceData attendance;
  final String? photoUrl;

  double get averageScore {
    if (subjects.isEmpty) return 0;
    final total =
        subjects.map((s) => s.score).reduce((a, b) => a + b);
    return total / subjects.length;
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
    List<SubjectScore>? subjects,
    DisciplinePoints? disciplinePoints,
    AttendanceData? attendance,
    String? photoUrl,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      nisn: nisn ?? this.nisn,
      className: className ?? this.className,
      subjects: subjects ?? this.subjects,
      disciplinePoints: disciplinePoints ?? this.disciplinePoints,
      attendance: attendance ?? this.attendance,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
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
    required this.name,
    required this.score,
    required this.teacher,
    required this.icon,
    this.details = const [],
  });

  final int id;
  final int subjectId;
  final String name;
  final double score;
  final String teacher;
  final String icon; // Material icon name
  final List<ScoreDetail> details;

  bool get isPassing => score >= 75;
  String get status => isPassing ? 'LULUS' : 'PERBAIKAN';

  SubjectScore copyWith({
    double? score,
    List<ScoreDetail>? details,
  }) {
    return SubjectScore(
      id: id,
      subjectId: subjectId,
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
