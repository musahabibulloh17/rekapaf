import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/rekap_repository.dart';
import '../models/student.dart';
import '../theme/rekap_theme.dart';
import '../widgets/loading_indicator.dart';

class InputDisciplineScreen extends StatefulWidget {
  const InputDisciplineScreen({super.key, required this.student});
  final Student student;

  @override
  State<InputDisciplineScreen> createState() => _InputDisciplineScreenState();
}

class _InputDisciplineScreenState extends State<InputDisciplineScreen> {
  late Student _student;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final updated = await RekapRepository.instance.getStudentById(_student.id);
      if (updated != null && mounted) {
        setState(() => _student = updated);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              title: const Text('Input Poin Tatib'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
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
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Poin (cth: 10 untuk prestasi, -5 untuk pelanggaran)',
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Data tidak valid')));
        }
        return;
      }

      setState(() => _isLoading = true);
      try {
        final finalCategory = points > 0 ? 'Prestasi' : 'Pelanggaran';
        await RekapRepository.instance.addDisciplineRecord(
          studentId: widget.student.id,
          title: title,
          category: finalCategory,
          date: DateTime.now().toIso8601String().split('T')[0],
          points: points,
          icon: points > 0 ? 'star' : 'flag',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Poin tatib berhasil ditambahkan')),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editDisciplinePoint(DisciplineRecord record) async {
    final titleController = TextEditingController(text: record.title);
    final pointsController = TextEditingController(text: record.points.abs().toString());
    String category = record.category;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Poin Tatib'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pointsController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Poin (cth: 10 atau -5)',
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

      if (title.isEmpty || points == null) return;

      setState(() => _isLoading = true);
      try {
        final finalCategory = points > 0 ? 'Prestasi' : 'Pelanggaran';
        await RekapRepository.instance.updateDisciplineRecord(
          id: record.id,
          title: title,
          category: finalCategory,
          date: record.date.toIso8601String().split('T')[0],
          points: points,
          icon: points > 0 ? 'star' : 'flag',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Poin tatib berhasil diperbarui')),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDisciplinePoint(DisciplineRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan tatib ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: RekapTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await RekapRepository.instance.deleteDisciplineRecord(record.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catatan tatib berhasil dihapus')),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = _student.disciplinePoints.records;

    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: Text('Tatib: ${_student.name}'),
        backgroundColor: Colors.white,
        foregroundColor: RekapTheme.onSurface,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Riwayat Tatib',
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
                        Icon(
                          Icons.history,
                          size: 48,
                          color: RekapTheme.outline,
                        ),
                        const SizedBox(height: 16),
                        const Text('Belum ada catatan tatib.'),
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
                            color: isPositive
                                ? RekapTheme.primary
                                : RekapTheme.error,
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isPositive ? '+${r.points}' : '${r.points}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isPositive
                                    ? RekapTheme.primary
                                    : RekapTheme.error,
                              ),
                            ),
                            if (RekapRepository.instance.currentUser.isSuperAdmin) ...[
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _editDisciplinePoint(r);
                                  } else if (val == 'delete') {
                                    _deleteDisciplinePoint(r);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 18, color: RekapTheme.error),
                                        SizedBox(width: 8),
                                        Text('Hapus', style: TextStyle(color: RekapTheme.error)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
