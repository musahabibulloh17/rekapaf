import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/rekap_repository.dart';
import '../models/student.dart';
import '../theme/rekap_theme.dart';

class InputGradesScreen extends StatefulWidget {
  const InputGradesScreen({super.key, required this.subjectScore, required this.studentId});
  final SubjectScore subjectScore;
  final int studentId;

  @override
  State<InputGradesScreen> createState() => _InputGradesScreenState();
}

class _InputGradesScreenState extends State<InputGradesScreen> {
  bool _isLoading = false;

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
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil menambahkan nilai')),
          );
          Navigator.pop(context); // Go back to refresh student list
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
    // In a real app we'd fetch the latest student state using a Stream or Provider.
    // For simplicity, we use the passed in subjectScore which contains details.
    // When a detail is added, we pop to previous screen to trigger reload.
    
    final details = widget.subjectScore.details;

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: Text('Nilai ${widget.subjectScore.name}'),
        backgroundColor: Colors.white,
        foregroundColor: RekapTheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        const Text('Belum ada rincian nilai.'),
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
