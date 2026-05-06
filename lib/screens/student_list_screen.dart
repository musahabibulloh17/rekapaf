import 'package:flutter/material.dart';

import '../data/rekap_repository.dart';
import '../models/student.dart';
import '../theme/rekap_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository.instance;
    final filteredStudents = repo.students.where((s) {
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
                      const Text(
                        'Daftar Siswa',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: RekapTheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${repo.students.length} siswa terdaftar',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: RekapTheme.onSurfaceVariant,
                        ),
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
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
  Future<void> _openDisciplineDetail() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InputDisciplineScreen(student: widget.student),
      ),
    );
    // When returning, if data was changed, the parent should reload. 
    // Usually handled by state management, but here we can just rebuild.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: Text(student.name),
        backgroundColor: Colors.white,
        foregroundColor: RekapTheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header
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
                      student.name.characters.first,
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
                        student.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: RekapTheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'NISN: ${student.nisn} • Kelas: ${student.className}',
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
          Row(
            children: [
              Expanded(
                child: _DetailStatCard(
                  label: 'Rata-rata',
                  value: student.averageScore.toStringAsFixed(1),
                  icon: Icons.assessment,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailStatCard(
                  label: 'Disiplin',
                  value: student.disciplinePoints.totalPoints.toString(),
                  icon: Icons.verified_user,
                  onTap: _openDisciplineDetail,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailStatCard(
                  label: 'Kehadiran',
                  value: '${student.attendance.percentage.toInt()}%',
                  icon: Icons.event_available,
                ),
              ),
            ],
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
          ...student.subjects.map(
            (subject) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SubjectDetailTile(
                subject: subject,
                studentId: student.id,
              ),
            ),
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

class _SubjectDetailTile extends StatefulWidget {
  const _SubjectDetailTile({required this.subject, required this.studentId});
  final SubjectScore subject;
  final int studentId;

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
                    widget.subject.score.toInt().toString(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: widget.subject.isPassing
                          ? RekapTheme.primary
                          : RekapTheme.error,
                    ),
                  ),
                  Text(
                    widget.subject.status,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.subject.isPassing
                          ? RekapTheme.primary
                          : RekapTheme.error,
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
