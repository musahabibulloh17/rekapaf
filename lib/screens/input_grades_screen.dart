import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/rekap_repository.dart';
import '../models/student.dart';
import '../services/auth_service.dart';
import '../theme/rekap_theme.dart';
import '../widgets/loading_indicator.dart';

class InputGradesScreen extends StatefulWidget {
  const InputGradesScreen({
    super.key,
    required this.subjectScore,
    required this.studentId,
    this.student,
    this.initialGrade,
    this.initialSemester,
  });
  final SubjectScore subjectScore;
  final int studentId;
  final Student? student;
  final int? initialGrade;
  final String? initialSemester;

  @override
  State<InputGradesScreen> createState() => _InputGradesScreenState();
}

class _InputGradesScreenState extends State<InputGradesScreen> {
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  bool get _isSuperAdmin => AuthService.instance.currentUser?.isSuperAdmin ?? false;

  // Period selection for superadmin
  int? _selectedGrade;
  String? _selectedSemester;
  List<Map<String, dynamic>> _periodOptions = [];

  // Current subject score with details for selected period
  SubjectScore? _currentSubjectScore;

  @override
  void initState() {
    super.initState();
    _initializePeriodOptions();
    _currentSubjectScore = widget.subjectScore;
  }

  void _initializePeriodOptions() {
    final student = widget.student;
    if (_isSuperAdmin && student != null) {
      // Build options from current period + all histories
      _periodOptions = [
        {
          'gradeLevel': student.gradeLevel,
          'semester': student.semester,
          'academicYear': student.academicYear,
          'label': 'Kelas ${student.gradeLevel} - ${student.semester} (Saat Ini)',
        },
        ...student.histories.map((h) => {
          'gradeLevel': h.gradeLevel,
          'semester': h.semester,
          'academicYear': h.academicYear,
          'label': 'Kelas ${h.gradeLevel} - ${h.semester}',
        }),
      ];
      _selectedGrade = widget.initialGrade ?? student.gradeLevel;
      _selectedSemester = widget.initialSemester ?? student.semester;
    } else {
      // Use the subject's grade level and semester
      _selectedGrade = widget.subjectScore.gradeLevel;
      _selectedSemester = widget.initialSemester ?? widget.student?.semester ?? 'Ganjil';
    }
  }

  /// Reload subject score details for the current period
  Future<void> _reloadDetails() async {
    if (widget.student == null || _selectedGrade == null || _selectedSemester == null) return;

    setState(() => _isLoadingDetails = true);

    // Fetch student data for the selected period using both gradeLevel and semester
    final updatedStudent = await RekapRepository.instance.getStudentById(
      widget.studentId,
      gradeLevel: _selectedGrade!,
      semester: _selectedSemester!,
    );

    if (updatedStudent != null && mounted) {
      // Find the subject score for this subject
      final subjectScore = updatedStudent.subjects.firstWhere(
        (s) => s.subjectId == widget.subjectScore.subjectId,
        orElse: () => widget.subjectScore,
      );

      setState(() {
        _currentSubjectScore = subjectScore;
        _isLoadingDetails = false;
      });
    } else {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  void _onPeriodChanged() {
    // Reload details for the new period
    _reloadDetails();
  }

  void _showPeriodSelector() {
    if (!_isSuperAdmin || widget.student == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Periode Akademik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Superadmin dapat input nilai untuk semester sebelumnya',
              style: TextStyle(
                fontSize: 12,
                color: RekapTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ..._periodOptions.map((opt) {
              final isSelected = _selectedGrade == opt['gradeLevel'] &&
                  _selectedSemester == opt['semester'];
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? RekapTheme.primary : RekapTheme.outline,
                ),
                title: Text(
                  opt['label'],
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? RekapTheme.primary : null,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedGrade = opt['gradeLevel'];
                    _selectedSemester = opt['semester'];
                  });
                  Navigator.pop(ctx);
                  _onPeriodChanged();
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _addGrade() async {
    final nameController = TextEditingController();
    final scoreController = TextEditingController();
    String selectedType = 'tugas';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Nilai Baru'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'tugas', child: Text('Tugas')),
                      DropdownMenuItem(value: 'uts', child: Text('UTS')),
                      DropdownMenuItem(value: 'uas', child: Text('UAS')),
                      DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                        if (nameController.text.isEmpty) {
                          if (val == 'uts') nameController.text = 'UTS';
                          if (val == 'uas') nameController.text = 'UAS';
                        }
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Jenis Nilai',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama / Keterangan (cth: Tugas 1)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nilai (0-100)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final name = nameController.text.trim();
      final scoreStr = scoreController.text.trim();
      final score = double.tryParse(scoreStr);

      if (name.isEmpty || score == null || score < 0 || score > 100) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data tidak valid')),
          );
        }
        return;
      }

      setState(() => _isLoading = true);
      try {
        await RekapRepository.instance.addScoreDetail(
          studentId: widget.studentId,
          subjectId: widget.subjectScore.subjectId,
          name: name,
          type: selectedType,
          score: score,
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          gradeLevel: _selectedGrade,
          semester: _selectedSemester,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil menambahkan nilai')),
          );
          // Reload details after adding
          _reloadDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the current subject score with details for the selected period
    final subjectScore = _currentSubjectScore ?? widget.subjectScore;
    final details = subjectScore.details;
    final currentPeriodLabel = 'Kelas ${_selectedGrade ?? widget.subjectScore.gradeLevel} - ${_selectedSemester ?? 'Ganjil'}';

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nilai ${widget.subjectScore.name}'),
            if (_isSuperAdmin && widget.student != null)
              GestureDetector(
                onTap: _showPeriodSelector,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentPeriodLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: RekapTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.swap_horiz,
                      size: 14,
                      color: RekapTheme.primary,
                    ),
                  ],
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: RekapTheme.onSurface,
        actions: [
          if (_isSuperAdmin && widget.student != null)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Ganti Periode',
              onPressed: _showPeriodSelector,
            ),
        ],
      ),
      body: _isLoading || _isLoadingDetails
          ? const LoadingIndicator()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rincian Nilai',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: RekapTheme.onSurface,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _addGrade,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah'),
                      style: FilledButton.styleFrom(
                        backgroundColor: RekapTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (details.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: RekapTheme.outline),
                        const SizedBox(height: 16),
                        const Text('Belum ada rincian nilai untuk periode ini.'),
                      ],
                    ),
                  )
                else
                  ...details.map((d) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          d.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          d.date != null ? DateFormat('d MMM yyyy').format(d.date!) : '-',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: RekapTheme.primaryFixed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            d.score.toInt().toString(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: RekapTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
