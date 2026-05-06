import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/rekap_repository.dart';
import '../models/student.dart';
import '../theme/rekap_theme.dart';

class InputDisciplineScreen extends StatefulWidget {
  const InputDisciplineScreen({super.key, required this.student});
  final Student student;

  @override
  State<InputDisciplineScreen> createState() => _InputDisciplineScreenState();
}

class _InputDisciplineScreenState extends State<InputDisciplineScreen> {
  bool _isLoading = false;

  Future<void> _addDisciplinePoint() async {
    final titleController = TextEditingController();
    final pointsController = TextEditingController();
    String category = 'Pelanggaran Ringan';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Input Poin Disiplin'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: const [
                      DropdownMenuItem(value: 'Prestasi', child: Text('Prestasi (+)')),
                      DropdownMenuItem(value: 'Pelanggaran Ringan', child: Text('Pelanggaran Ringan (-)')),
                      DropdownMenuItem(value: 'Pelanggaran Berat', child: Text('Pelanggaran Berat (-)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan (cth: Datang terlambat)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Poin (angka positif atau negatif)',
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
      final title = titleController.text.trim();
      final points = int.tryParse(pointsController.text.trim());

      if (title.isEmpty || points == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data tidak valid')),
          );
        }
        return;
      }

      setState(() => _isLoading = true);
      try {
        await RekapRepository.instance.addDisciplineRecord(
          studentId: widget.student.id,
          title: title,
          category: category,
          date: DateTime.now().toIso8601String().split('T')[0],
          points: category == 'Prestasi' ? points.abs() : -points.abs(),
          icon: category == 'Prestasi' ? 'star' : 'flag',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Poin berhasil ditambahkan')),
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
    final records = widget.student.disciplinePoints.records;

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: Text('Disiplin: ${widget.student.name}'),
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
                      'Riwayat Disiplin',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: RekapTheme.onSurface,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _addDisciplinePoint,
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
                if (records.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: RekapTheme.outline),
                        const SizedBox(height: 16),
                        const Text('Belum ada catatan disiplin.'),
                      ],
                    ),
                  )
                else
                  ...records.map((r) {
                    final isPositive = r.isPositive;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? RekapTheme.primaryFixed
                                : RekapTheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPositive ? Icons.star : Icons.flag,
                            color: isPositive ? RekapTheme.primary : RekapTheme.error,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          r.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${r.category} • ${DateFormat('d MMM yyyy').format(r.date)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          isPositive ? '+${r.points}' : '${r.points}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isPositive ? RekapTheme.primary : RekapTheme.error,
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
