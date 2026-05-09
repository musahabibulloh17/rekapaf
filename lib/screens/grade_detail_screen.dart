import 'package:flutter/material.dart';

import '../data/rekap_repository.dart';
import '../models/student.dart';
import '../theme/rekap_theme.dart';
import '../widgets/loading_indicator.dart';
import '../services/api_service.dart';
import 'package:open_filex/open_filex.dart';

/// Detail Nilai Real-time – Grade Detail Screen (User/Parent view)
/// Matches: detail-nilai-realtime-user.html
class GradeDetailScreen extends StatefulWidget {
  const GradeDetailScreen({super.key, this.onRefresh});
  final VoidCallback? onRefresh;

  @override
  State<GradeDetailScreen> createState() => _GradeDetailScreenState();
}

class _GradeDetailScreenState extends State<GradeDetailScreen> {
  Student? _student;
  bool _isLoading = false;
  int? _selectedGrade;
  String? _selectedSemester;

  @override
  void initState() {
    super.initState();
    _student = RekapRepository.instance.childStudent;
    if (_student != null) {
      _selectedGrade = _student!.gradeLevel;
      _selectedSemester = _student!.semester;
    }
  }

  Future<void> _updateFilter(int grade, String semester, String academicYear) async {
    final original = RekapRepository.instance.childStudent;
    if (original == null) return;

    setState(() {
      _selectedGrade = grade;
      _selectedSemester = semester;
      _isLoading = true;
    });

    final updated = await RekapRepository.instance.getStudentById(
      original.id,
      gradeLevel: grade,
      semester: semester,
      academicYear: academicYear,
    );

    if (mounted) {
      setState(() {
        if (updated != null) _student = updated;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPDF() async {
    if (_student == null) return;
    
    setState(() => _isLoading = true);
    try {
      final student = _student!;
      final fileName = 'Rapot_${student.name}_Kelas_${_selectedGrade}_${_selectedSemester}.pdf';
      
      final path = await ApiService.download(
        '/scores/export/report-pdf/${student.id}?grade_level=${_selectedGrade}&semester=${_selectedSemester}&academic_year=${student.academicYear}',
        fileName,
      );

      if (path != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rapot berhasil diunduh: $fileName'),
              action: SnackBarAction(
                label: 'Buka',
                onPressed: () => OpenFilex.open(path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunduh rapot: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;

    if (student == null) {
      return Scaffold(
        backgroundColor: RekapTheme.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined, size: 64, color: RekapTheme.outline),
              const SizedBox(height: 16),
              const Text('Belum ada data nilai', style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                if (widget.onRefresh != null) widget.onRefresh!();
                await _updateFilter(_selectedGrade!, _selectedSemester!, _student!.academicYear);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _HeroSection(student: student),
                  const SizedBox(height: 20),
                  _PeriodFilter(
                    currentGrade: _selectedGrade!,
                    currentSemester: _selectedSemester!,
                    student: RekapRepository.instance.childStudent!, // Use original for history options
                    onChanged: _updateFilter,
                  ),
                  const SizedBox(height: 20),
                  _TrendChart(student: student),
                  const SizedBox(height: 20),
                  _SubjectListCard(
                    subjects: student.subjects,
                    onExportPDF: _exportPDF,
                  ),
                  const SizedBox(height: 20),
                  _AttendanceCard(attendance: student.attendance),
                  const SizedBox(height: 20),
                  _RecommendationCard(student: student),
                  const SizedBox(height: 20),
                  _DisciplineNoteCard(student: student),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.1),
                child: const LoadingIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RekapTheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: RekapTheme.primaryContainer.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RATA-RATA SEMESTER',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: RekapTheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            student.averageScore.toStringAsFixed(1),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: RekapTheme.onPrimaryContainer,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 14,
                  color: RekapTheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '+2.4 Poin dari bulan lalu',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: RekapTheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Student info at bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      student.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: RekapTheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelas ${student.className} • NISN: ${student.nisn}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: RekapTheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
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
class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({
    required this.currentGrade,
    required this.currentSemester,
    required this.student,
    required this.onChanged,
  });

  final int currentGrade;
  final String currentSemester;
  final Student student;
  final void Function(int grade, String semester, String academicYear) onChanged;

  @override
  Widget build(BuildContext context) {
    // Generate options from current state and histories (filter duplicates)
    final List<Map<String, dynamic>> options = [
      {
        'grade': student.gradeLevel,
        'semester': student.semester,
        'academicYear': student.academicYear,
        'label': 'Kelas ${student.gradeLevel} - ${student.semester} (Aktif)',
      },
      ...student.histories
          .where((h) => !(h.gradeLevel == student.gradeLevel && h.semester == student.semester))
          .map((h) => {
                'grade': h.gradeLevel,
                'semester': h.semester,
                'academicYear': h.academicYear,
                'label': 'Kelas ${h.gradeLevel} - ${h.semester}',
              }),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RekapTheme.surfaceContainer),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: options.indexWhere((o) => o['grade'] == currentGrade && o['semester'] == currentSemester),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: RekapTheme.primary),
          items: List.generate(options.length, (index) {
            final opt = options[index];
            return DropdownMenuItem<int>(
              value: index,
              child: Text(
                opt['label'],
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: RekapTheme.onSurface,
                ),
              ),
            );
          }),
          onChanged: (index) {
            if (index != null) {
              onChanged(
                options[index]['grade'], 
                options[index]['semester'],
                options[index]['academicYear'],
              );
            }
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    final isGenap = student.semester.toLowerCase() == 'genap';
    final monthLabels = isGenap
        ? ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN']
        : ['JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
    final monthIndices = isGenap ? [1, 2, 3, 4, 5, 6] : [7, 8, 9, 10, 11, 12];

    final Map<int, List<double>> groupedScores = {};
    for (var m in monthIndices) {
      groupedScores[m] = [];
    }

    for (var subject in student.subjects) {
      for (var detail in subject.details) {
        if (detail.date != null) {
          final m = detail.date!.month;
          if (groupedScores.containsKey(m)) {
            groupedScores[m]!.add(detail.score);
          }
        }
      }
    }

    final List<double> averages = List.generate(6, (i) {
      final scores = groupedScores[monthIndices[i]]!;
      if (scores.isEmpty) return 0.0;
      return scores.reduce((a, b) => a + b) / scores.length;
    });

    final maxAvg = averages.reduce((a, b) => a > b ? a : b);
    final displayMax = maxAvg > 0 ? maxAvg : 100.0;

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
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tren Perkembangan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: RekapTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rata-rata nilai per bulan semester ini',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: RekapTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.show_chart, color: RekapTheme.primary),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final avg = averages[i];
                final heightFactor = avg / displayMax;
                final isHighest = avg > 0 && avg == maxAvg;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (avg > 0)
                          Text(
                            avg.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isHighest ? RekapTheme.primary : RekapTheme.outline,
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: (avg > 0 ? (heightFactor * 140) + 10 : 2.0),
                          decoration: BoxDecoration(
                            color: avg == 0
                                ? RekapTheme.surfaceContainer
                                : (isHighest
                                    ? RekapTheme.primary
                                    : RekapTheme.primary.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          monthLabels[i],
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SubjectListCard extends StatelessWidget {
  const _SubjectListCard({required this.subjects, required this.onExportPDF});
  final List<SubjectScore> subjects;
  final VoidCallback onExportPDF;

  IconData _iconForSubject(String iconName) {
    switch (iconName) {
      case 'calculate':
        return Icons.calculate;
      case 'language':
        return Icons.language;
      case 'science':
        return Icons.science;
      case 'history_edu':
        return Icons.history_edu;
      case 'public':
        return Icons.public;
      case 'mosque':
        return Icons.mosque;
      default:
        return Icons.book;
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
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Detail Mata Pelajaran',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: RekapTheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onExportPDF,
                  child: const Text(
                    'Unduh PDF',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: RekapTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          ...subjects.map((subject) => _SubjectRow(
                subject: subject,
                icon: _iconForSubject(subject.icon),
                isLast: subject == subjects.last,
              )),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.icon,
    this.isLast = false,
  });
  final SubjectScore subject;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: const EdgeInsets.only(left: 78, right: 20, bottom: 16),
            title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: RekapTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pengajar: ${subject.teacher}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: RekapTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    subject.score?.toInt().toString() ?? '-',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: subject.score == null 
                          ? RekapTheme.outline 
                          : (subject.isPassing ? RekapTheme.primary : RekapTheme.secondary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: subject.score == null 
                          ? RekapTheme.surfaceContainer
                          : (subject.isPassing ? const Color(0xFFDCFCE7) : RekapTheme.secondaryContainer),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      subject.score == null ? 'BELUM ADA' : subject.status,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: subject.score == null 
                            ? RekapTheme.outline 
                            : (subject.isPassing ? const Color(0xFF15803D) : RekapTheme.secondary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (subject.details.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text('Belum ada rincian nilai',
                    style: TextStyle(color: RekapTheme.onSurfaceVariant, fontSize: 13)),
              )
            else
              ...subject.details.map((detail) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _ScoreBreakdownRow(label: detail.name, score: detail.score),
                );
              }),
          ],
        ),
      ),
      if (!isLast)
          const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF8FAFC),
          ),
      ],
    );
  }
}

class _ScoreBreakdownRow extends StatelessWidget {
  const _ScoreBreakdownRow({required this.label, this.score});
  final String label;
  final double? score;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: RekapTheme.onSurfaceVariant,
          ),
        ),
        Text(
          score != null ? score!.toInt().toString() : '-',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RekapTheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.attendance});
  final AttendanceData attendance;

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
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Presensi',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: RekapTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: attendance.percentage / 100,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          RekapTheme.primary,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${attendance.percentage.toInt()}%',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: RekapTheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance.status,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: RekapTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Hanya ${attendance.izin + attendance.sakit + attendance.alfa} kali absen semester ini',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: RekapTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _AttendanceStat(label: 'IZIN', value: attendance.izin),
              const SizedBox(width: 8),
              _AttendanceStat(label: 'SAKIT', value: attendance.sakit),
              const SizedBox(width: 8),
              _AttendanceStat(label: 'ALFA', value: attendance.alfa),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  const _AttendanceStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: RekapTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: RekapTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: RekapTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    final subjectsWithScores = student.subjects.where((s) => s.score != null).toList();
    if (subjectsWithScores.isEmpty) return const SizedBox.shrink();

    final weakSubject = subjectsWithScores.reduce(
      (a, b) => (a.score ?? 101) < (b.score ?? 101) ? a : b,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: RekapTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Rekomendasi Belajar',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14532D),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF166534),
                height: 1.6,
              ),
              children: [
                const TextSpan(text: 'Berdasarkan nilai '),
                TextSpan(
                  text: weakSubject.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text:
                      ' yang menurun, kami menyarankan untuk mengikuti sesi pengayaan besok siang.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: RekapTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Daftar Pengayaan',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _DisciplineNoteCard extends StatelessWidget {
  const _DisciplineNoteCard({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    final lastRecord =
        student.disciplinePoints.records.isNotEmpty
            ? student.disciplinePoints.records.first
            : null;

    if (lastRecord == null) return const SizedBox.shrink();

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
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user,
                color: Color(0xFF15803D),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Catatan Disiplin',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: RekapTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 48,
                decoration: BoxDecoration(
                  color: lastRecord.isPositive
                      ? const Color(0xFF22C55E)
                      : RekapTheme.error,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(lastRecord.date),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: RekapTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastRecord.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: RekapTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lastRecord.isPositive ? '+' : ''}${lastRecord.points} POIN ${lastRecord.category.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: lastRecord.isPositive
                            ? const Color(0xFF15803D)
                            : RekapTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
