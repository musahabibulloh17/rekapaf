import 'package:flutter/material.dart';

import '../data/rekap_repository.dart';
import '../models/student.dart';
import '../theme/rekap_theme.dart';
import 'input_discipline_screen.dart';

/// Discipline Management Screen (Guru/Superadmin)
class DisciplineManagementScreen extends StatefulWidget {
  const DisciplineManagementScreen({super.key, this.onRefresh});
  final VoidCallback? onRefresh;

  @override
  State<DisciplineManagementScreen> createState() =>
      _DisciplineManagementScreenState();
}

class _DisciplineManagementScreenState
    extends State<DisciplineManagementScreen> {
  String _searchQuery = '';
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository.instance;
    final classOptions =
        repo.students
            .map((s) => s.className)
            .where((name) => name.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (_selectedClass != null && !classOptions.contains(_selectedClass)) {
      _selectedClass = null;
    }

    final students = repo.students.where((s) {
      if (_selectedClass != null && s.className != _selectedClass) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.nisn.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: const Text('Manajemen Tatib'),
        backgroundColor: Colors.white,
        foregroundColor: RekapTheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          } else {
            await repo.refresh();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _SearchBar(
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),
            _ClassFilter(
              classes: classOptions,
              selectedClass: _selectedClass,
              onChanged: (value) => setState(() => _selectedClass = value),
            ),
            const SizedBox(height: 16),
            if (students.isEmpty)
              _EmptyState(onRefresh: widget.onRefresh)
            else
              ...students.map(
                (student) => _StudentDisciplineCard(student: student),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentDisciplineCard extends StatelessWidget {
  const _StudentDisciplineCard({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    final points = student.disciplinePoints.totalPoints;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${student.nisn} • ${student.className}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              points.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: points >= 0 ? RekapTheme.primary : RekapTheme.error,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Poin', style: TextStyle(fontSize: 11)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InputDisciplineScreen(student: student),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Cari siswa atau NISN',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: RekapTheme.surfaceContainer),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: RekapTheme.surfaceContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RekapTheme.primary),
        ),
      ),
    );
  }
}

class _ClassFilter extends StatelessWidget {
  const _ClassFilter({
    required this.classes,
    required this.selectedClass,
    required this.onChanged,
  });

  final List<String> classes;
  final String? selectedClass;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedClass,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Filter Kelas',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: RekapTheme.surfaceContainer),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: RekapTheme.surfaceContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RekapTheme.primary),
        ),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Semua Kelas')),
        ...classes.map(
          (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: RekapTheme.outline),
          const SizedBox(height: 16),
          const Text('Belum ada data siswa'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}
