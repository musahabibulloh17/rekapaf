import 'package:flutter/material.dart';

import '../data/rekap_repository.dart';
import '../models/student.dart';
import '../models/classroom.dart';
import '../theme/rekap_theme.dart';
import '../widgets/loading_indicator.dart';
import 'input_discipline_screen.dart';
import 'input_grades_screen.dart';

/// Daftar Siswa & Rekap Nilai – Student List Screen (Admin view)
/// Matches: daftar-siswa-rekap-nilai-admin.html
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key, this.onRefresh});
  final VoidCallback? onRefresh;

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';
  Classroom? _selectedClassroom;

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository.instance;
    
    if (_selectedClassroom == null) {
      return _buildClassroomList(repo);
    }

    final filteredStudents = repo.students.where((s) {
      // Filter by class first
      if (s.className != _selectedClassroom!.name) return false;
      
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.nisn.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (widget.onRefresh != null) {
              widget.onRefresh!();
            } else {
              await repo.refresh();
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _selectedClassroom = null),
                            icon: const Icon(Icons.arrow_back),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Siswa ${_selectedClassroom!.name}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: RekapTheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${filteredStudents.length} siswa di kelas ini',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: RekapTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SearchBar(
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (filteredStudents.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: RekapTheme.outline),
                        const SizedBox(height: 16),
                        const Text('Tidak ada siswa ditemukan',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 15)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final student = filteredStudents[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _StudentCard(
                            student: student,
                            onTap: () => _onStudentTap(context, student),
                          ),
                        );
                      },
                      childCount: filteredStudents.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassroomList(RekapRepository repo) {
    return Scaffold(
      backgroundColor: RekapTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (widget.onRefresh != null) {
              widget.onRefresh!();
            } else {
              await repo.refresh();
            }
          },
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar Kelas',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: RekapTheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pilih kelas untuk melihat daftar siswa',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: RekapTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (repo.classrooms.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.class_outlined, size: 64, color: RekapTheme.outline),
                        const SizedBox(height: 16),
                        const Text('Tidak ada kelas ditemukan',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 15)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final classroom = repo.classrooms[index];
                      final studentCount = repo.students
                          .where((s) => s.className == classroom.name)
                          .length;
                      return _ClassroomCard(
                        classroom: classroom,
                        studentCount: studentCount,
                        onTap: () => setState(() => _selectedClassroom = classroom),
                      );
                    },
                    childCount: repo.classrooms.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  void _onStudentTap(BuildContext context, Student student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StudentDetailPage(student: student),
      ),
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  const _ClassroomCard({
    required this.classroom,
    required this.studentCount,
    required this.onTap,
  });

  final Classroom classroom;
  final int studentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RekapTheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RekapTheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.class_outlined,
                  color: RekapTheme.primary,
                  size: 24,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroom.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: RekapTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$studentCount Siswa',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: RekapTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RekapTheme.outlineVariant),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search student name or ID...',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: RekapTheme.outline,
          ),
          prefixIcon: Icon(Icons.search, color: RekapTheme.outline),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.onTap});
  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          border: Border.all(color: const Color(0xFFF8FAFC)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Student info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: RekapTheme.primaryFixed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      student.name.characters.first,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: RekapTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: RekapTheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NISN: ${student.nisn}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: RekapTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: RekapTheme.outline,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StudentStatBox(
                    label: 'NILAI RATA-RATA',
                    value: student.averageScore.toStringAsFixed(1),
                    suffix: '/100',
                    valueColor: RekapTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StudentStatBox(
                    label: 'POIN TATA TERTIB',
                    value: student.disciplinePoints.totalPoints.toString(),
                    suffix: 'PTS',
                    valueColor: student.disciplinePoints.totalPoints >= 200
                        ? RekapTheme.secondary
                        : RekapTheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Progress bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ACADEMIC PROGRESS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: RekapTheme.outline,
                      ),
                    ),
                    Text(
                      student.academicStatus,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: student.averageScore >= 85
                            ? RekapTheme.primary
                            : RekapTheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: student.averageScore / 100,
                    minHeight: 8,
                    backgroundColor: RekapTheme.secondaryContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      RekapTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentStatBox extends StatelessWidget {
  const _StudentStatBox({
    required this.label,
    required this.value,
    required this.suffix,
    required this.valueColor,
  });
  final String label;
  final String value;
  final String suffix;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RekapTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: RekapTheme.outline,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                suffix,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: valueColor.withValues(alpha: 0.7),
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
// Student Detail Page (navigated from student list)
// ─────────────────────────────────────────────────────────────────────────────
class _StudentDetailPage extends StatefulWidget {
  const _StudentDetailPage({required this.student});
  final Student student;

  @override
  State<_StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<_StudentDetailPage> {
  Student? _student;
  bool _isLoading = false;
  int? _selectedGrade;
  String? _selectedSemester;

  // Get all available periods (rely on API sorted histories)
  List<Map<String, dynamic>> get _allPeriods {
    final student = _student ?? widget.student;
    return student.histories.map((h) => {
      'gradeLevel': h.gradeLevel,
      'semester': h.semester,
      'academicYear': h.academicYear,
      'isCurrent': h.gradeLevel == widget.student.gradeLevel && 
                   h.semester == widget.student.semester,
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    if (_student != null) {
      _selectedGrade = _student!.gradeLevel;
      _selectedSemester = _student!.semester;
    }
  }

  Future<void> _updateFilter(int grade, String semester, String academicYear, {bool force = false}) async {
    // Don't reload if same filter (unless forced)
    if (!force && _selectedGrade == grade && _selectedSemester == semester) return;

    setState(() {
      _selectedGrade = grade;
      _selectedSemester = semester;
      _isLoading = true;
    });

    final updated = await RekapRepository.instance.getStudentById(
      widget.student.id,
      gradeLevel: grade,
      semester: semester,
      academicYear: academicYear,
    );

    if (mounted) {
      setState(() {
        if (updated != null) {
          _student = updated;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _openDisciplineDetail() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InputDisciplineScreen(student: _student ?? widget.student),
      ),
    );
    if (mounted) {
      // Re-fetch to get latest points
      _updateFilter(_selectedGrade!, _selectedSemester!, _student!.academicYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: Text(_student?.name ?? widget.student.name),
        backgroundColor: Colors.white,
        foregroundColor: RekapTheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _updateFilter(
              _selectedGrade ?? widget.student.gradeLevel,
              _selectedSemester ?? widget.student.semester,
              _student?.academicYear ?? widget.student.academicYear,
              force: true,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // Profile Header
                if (_student != null)
                  Container(
                    decoration: BoxDecoration(
                      color: RekapTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              _student!.name.characters.first,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _student!.name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: RekapTheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                'NISN: ${_student!.nisn} • Kelas: ${_student!.className}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color:
                                      RekapTheme.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
      
                // Stats Grid
                if (_student != null)
                  Row(
                    children: [
                      Expanded(
                        child: _DetailStatCard(
                          label: 'Rata-rata',
                          value: _student!.averageScore.toStringAsFixed(1),
                          icon: Icons.assessment,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          label: 'Disiplin',
                          value: _student!.disciplinePoints.totalPoints.toString(),
                          icon: Icons.verified_user,
                          onTap: _openDisciplineDetail,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          label: 'Kehadiran',
                          value: '${_student!.attendance.percentage.toInt()}%',
                          icon: Icons.event_available,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
  
                // Period Filter
                const Text(
                  'Filter Masa Akademik',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: RekapTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _PeriodFilterDropdown(
                  currentGrade: _selectedGrade ?? widget.student.gradeLevel,
                  currentSemester: _selectedSemester ?? widget.student.semester,
                  student: widget.student,
                  onChanged: _updateFilter,
                  periods: _allPeriods,
                ),
                const SizedBox(height: 24),
      
                // Subjects
                const Text(
                  'Nilai Per Mata Pelajaran',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: RekapTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (_student != null)
                  ..._student!.subjects.map(
                    (subject) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SubjectDetailTile(
                        subject: subject,
                        studentId: _student!.id,
                        student: widget.student,
                        initialGrade: _selectedGrade,
                        initialSemester: _selectedSemester,
                      ),
                    ),
                  ),
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
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  const _DetailStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: RekapTheme.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: RekapTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: RekapTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _PeriodFilterDropdown extends StatelessWidget {
  const _PeriodFilterDropdown({
    required this.currentGrade,
    required this.currentSemester,
    required this.student,
    required this.onChanged,
    required this.periods,
  });

  final int currentGrade;
  final String currentSemester;
  final Student student;
  final void Function(int grade, String semester, String academicYear) onChanged;
  final List<Map<String, dynamic>> periods;

  @override
  Widget build(BuildContext context) {
    // Build options ensuring no duplicates
    final Map<String, Map<String, dynamic>> uniquePeriods = {};

    for (final p in periods) {
      final key = '${p['gradeLevel']}-${p['semester']}';
      if (!uniquePeriods.containsKey(key)) {
        uniquePeriods[key] = p;
      }
    }

    final options = uniquePeriods.values.toList();

    if (options.isEmpty) {
      // Fallback to current student data
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RekapTheme.surfaceContainer),
        ),
        child: Text(
          'Kelas ${student.gradeLevel} - ${student.semester} (Aktif)',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RekapTheme.onSurface,
          ),
        ),
      );
    }

    final selectedIndex = options.indexWhere(
      (o) => o['gradeLevel'] == currentGrade && o['semester'] == currentSemester,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RekapTheme.surfaceContainer),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedIndex >= 0 ? selectedIndex : 0,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: RekapTheme.primary),
          items: List.generate(options.length, (index) {
            final opt = options[index];
            final isCurrent = opt['isCurrent'] == true;
            return DropdownMenuItem<int>(
              value: index,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kelas ${opt['gradeLevel']} - ${opt['semester']}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: isCurrent ? RekapTheme.primary : RekapTheme.onSurface,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: RekapTheme.primaryFixed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Aktif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: RekapTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          onChanged: (index) {
            if (index != null) {
              onChanged(
                options[index]['gradeLevel'], 
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

class _SubjectDetailTile extends StatefulWidget {
  const _SubjectDetailTile({
    required this.subject, 
    required this.studentId, 
    this.student,
    this.initialGrade,
    this.initialSemester,
  });
  final SubjectScore subject;
  final int studentId;
  final Student? student;
  final int? initialGrade;
  final String? initialSemester;

  @override
  State<_SubjectDetailTile> createState() => _SubjectDetailTileState();
}

class _SubjectDetailTileState extends State<_SubjectDetailTile> {
  void _openInputGrades() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InputGradesScreen(
          subjectScore: widget.subject,
          studentId: widget.studentId,
          student: widget.student,
          initialGrade: widget.initialGrade,
          initialSemester: widget.initialSemester,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openInputGrades,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RekapTheme.surfaceContainer),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subject.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: RekapTheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.subject.teacher,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
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
                    widget.subject.score?.toInt().toString() ?? '-',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: widget.subject.score == null 
                          ? RekapTheme.outline 
                          : (widget.subject.isPassing ? RekapTheme.primary : RekapTheme.error),
                    ),
                  ),
                  Text(
                    widget.subject.score == null ? 'BELUM ADA' : widget.subject.status,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.subject.score == null 
                          ? RekapTheme.outline 
                          : (widget.subject.isPassing ? RekapTheme.primary : RekapTheme.error),
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 16, color: RekapTheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}
