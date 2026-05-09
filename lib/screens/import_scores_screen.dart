import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../data/rekap_repository.dart';
import '../models/classroom.dart';
import '../models/subject.dart';
import '../services/api_service.dart';
import '../theme/rekap_theme.dart';

class ImportScoresScreen extends StatefulWidget {
  const ImportScoresScreen({super.key});

  @override
  State<ImportScoresScreen> createState() => _ImportScoresScreenState();
}

class _ImportScoresScreenState extends State<ImportScoresScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teacherController = TextEditingController();
  
  Classroom? _selectedClass;
  Subject? _selectedSubject;
  String _selectedSemester = 'Ganjil';
  int _selectedGradeLevel = 12;
  String _academicYear = '';
  
  bool _isDownloading = false;
  bool _isImporting = false;
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _teacherController.text = RekapRepository.instance.currentUser.name;
    _academicYear = _getCurrentAcademicYear();
    
    // Default selections
    final repo = RekapRepository.instance;
    if (repo.classrooms.isNotEmpty) {
      _selectedClass = repo.classrooms.first;
    }
    if (repo.subjects.isNotEmpty) {
      _selectedSubject = repo.subjects.first;
    }
  }

  String _getCurrentAcademicYear() {
    final now = DateTime.now();
    final year = now.year;
    if (now.month >= 7) {
      return '$year/${year + 1}';
    } else {
      return '${year - 1}/$year';
    }
  }

  Future<void> _downloadTemplate() async {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kelas terlebih dahulu')),
      );
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final fileName = 'Template_Nilai_${_selectedClass!.name}.xlsx';
      final path = await ApiService.download(
        '/scores/template?class_name=${Uri.encodeComponent(_selectedClass!.name)}',
        fileName,
      );

      if (path != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template berhasil diunduh: $fileName'),
              action: SnackBarAction(
                label: 'Buka',
                onPressed: () => OpenFilex.open(path),
              ),
            ),
          );
        }
      } else {
        throw Exception('Gagal mengunduh file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunduh template: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _importData() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih file Excel terlebih dahulu')),
        );
      }
      return;
    }

    setState(() => _isImporting = true);
    try {
      await RekapRepository.instance.importScores(
        file: _selectedFile!,
        subjectId: _selectedSubject!.id,
        gradeLevel: _selectedGradeLevel,
        semester: _selectedSemester,
        academicYear: _academicYear,
        teacher: _teacherController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data nilai berhasil diimport!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengimport data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository.instance;
    
    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Import Nilai Excel',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: RekapTheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Konfigurasi Import',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: RekapTheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildCard([
                _buildDropdown<Classroom>(
                  label: 'Pilih Kelas',
                  value: _selectedClass,
                  items: repo.classrooms,
                  itemLabel: (c) => c.name,
                  onChanged: (val) => setState(() => _selectedClass = val),
                ),
                const SizedBox(height: 16),
                _buildDropdown<Subject>(
                  label: 'Mata Pelajaran',
                  value: _selectedSubject,
                  items: repo.subjects,
                  itemLabel: (s) => s.name,
                  onChanged: (val) => setState(() => _selectedSubject = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<int>(
                        label: 'Kelas (Level)',
                        value: _selectedGradeLevel,
                        items: [10, 11, 12],
                        itemLabel: (v) => v.toString(),
                        onChanged: (val) => setState(() => _selectedGradeLevel = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown<String>(
                        label: 'Semester',
                        value: _selectedSemester,
                        items: ['Ganjil', 'Genap'],
                        itemLabel: (v) => v,
                        onChanged: (val) => setState(() => _selectedSemester = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Tahun Akademik',
                  initialValue: _academicYear,
                  onChanged: (v) => _academicYear = v,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Nama Guru',
                  controller: _teacherController,
                ),
              ]),
              
              const SizedBox(height: 32),
              
              const Text(
                'Langkah 1: Download Template',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: RekapTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gunakan template ini agar format data sesuai dengan sistem.',
                style: TextStyle(fontSize: 12, color: RekapTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isDownloading ? null : _downloadTemplate,
                  icon: _isDownloading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_rounded),
                  label: Text(_isDownloading ? 'Downloading...' : 'Download Template Excel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: RekapTheme.primary),
                    foregroundColor: RekapTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Langkah 2: Upload File',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: RekapTheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFile != null ? RekapTheme.primary : RekapTheme.outlineVariant,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.description : Icons.upload_file,
                        size: 48,
                        color: _selectedFile != null ? RekapTheme.primary : RekapTheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile != null 
                          ? _selectedFile!.path.split('/').last 
                          : 'Ketuk untuk pilih file Excel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                          color: _selectedFile != null ? RekapTheme.onSurface : RekapTheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ganti File',
                          style: TextStyle(fontSize: 12, color: RekapTheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isImporting || _selectedFile == null) ? null : _importData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RekapTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isImporting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'IMPORT SEKARANG',
                        style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RekapTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: RekapTheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: RekapTheme.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    TextEditingController? controller,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RekapTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: RekapTheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: RekapTheme.outlineVariant),
            ),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Field ini wajib diisi' : null,
        ),
      ],
    );
  }
}
