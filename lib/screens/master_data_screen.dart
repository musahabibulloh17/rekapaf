import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/rekap_theme.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _classrooms = [];
  List<dynamic> _students = [];
  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final classRes = await ApiService.get('/classrooms');
      final studRes = await ApiService.get('/students');
      final accRes = await ApiService.get('/accounts');

      if (mounted) {
        setState(() {
          _classrooms = classRes['data'] ?? [];
          _students = studRes['data'] ?? [];
          _accounts = (accRes['data'] as List? ?? []).where((a) => a['role'] == 'guru' || a['role'] == 'wali_kelas').toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showClassForm({Map<String, dynamic>? classroom}) async {
    final nameCtrl = TextEditingController(text: classroom?['name']);
    int? selectedWaliKelasId = classroom?['wali_kelas_id'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: Text(classroom == null ? 'Tambah Kelas' : 'Edit Kelas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Kelas', hintText: 'Contoh: 10-A IPA'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _accounts.any((a) => a['id'] == selectedWaliKelasId) ? selectedWaliKelasId : null,
                decoration: const InputDecoration(labelText: 'Wali Kelas (Guru)'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('-- Belum Ditentukan --')),
                  ..._accounts.map((a) => DropdownMenuItem<int>(
                    value: a['id'],
                    child: Text(a['name']),
                  )),
                ],
                onChanged: (val) => setStateBuilder(() => selectedWaliKelasId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama kelas harus diisi')));
                  return;
                }
                Navigator.pop(ctx, {
                  'name': nameCtrl.text,
                  'wali_kelas_id': selectedWaliKelasId,
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        if (classroom == null) {
          await ApiService.post('/classrooms', result);
        } else {
          await ApiService.put('/classrooms/${classroom['id']}', result);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data kelas berhasil disimpan')));
          _loadData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addClass() => _showClassForm();

  Future<void> _deleteClass(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kelas'),
        content: const Text('Yakin ingin menghapus kelas ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete('/classrooms/$id');
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showStudentForm({Map<String, dynamic>? student}) async {
    final nisnCtrl = TextEditingController(text: student?['nisn']);
    final nameCtrl = TextEditingController(text: student?['name']);
    String? selectedClass = student?['class_name'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: Text(student == null ? 'Tambah Siswa' : 'Edit Siswa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nisnCtrl,
                  decoration: const InputDecoration(labelText: 'NISN'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _classrooms.any((c) => c['name'] == selectedClass) ? selectedClass : null,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: _classrooms.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['name'],
                      child: Text(c['name']),
                    );
                  }).toList(),
                  onChanged: (val) => setStateBuilder(() => selectedClass = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (nisnCtrl.text.isEmpty || nameCtrl.text.isEmpty || selectedClass == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua field harus diisi')));
                  return;
                }
                Navigator.pop(ctx, {
                  'nisn': nisnCtrl.text,
                  'name': nameCtrl.text,
                  'class_name': selectedClass,
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        if (student == null) {
          await ApiService.post('/students', result);
        } else {
          await ApiService.put('/students/${student['id']}', result);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data siswa berhasil disimpan')));
          _loadData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteStudent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: const Text('Yakin ingin menghapus siswa ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete('/students/$id');
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: const Text('Master Data'),
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: RekapTheme.primary,
          unselectedLabelColor: RekapTheme.onSurfaceVariant,
          indicatorColor: RekapTheme.primary,
          tabs: const [
            Tab(text: 'Kelas'),
            Tab(text: 'Siswa'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab Kelas
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _classrooms.length,
                    itemBuilder: (ctx, i) {
                      final c = _classrooms[i];
                      final waliKelasName = c['wali_kelas']?['name'] ?? 'Belum ditentukan';
                      return Card(
                        child: ListTile(
                          title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Wali Kelas: $waliKelasName'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: RekapTheme.primary),
                                onPressed: () => _showClassForm(classroom: c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: RekapTheme.error),
                                onPressed: () => _deleteClass(c['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Tab Siswa
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (ctx, i) {
                      final s = _students[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(s['name'][0].toUpperCase())),
                          title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${s['nisn']} • Kelas: ${s['class_name']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: RekapTheme.primary),
                                onPressed: () => _showStudentForm(student: s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: RekapTheme.error),
                                onPressed: () => _deleteStudent(s['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _addClass();
          } else {
            _showStudentForm();
          }
        },
        backgroundColor: RekapTheme.primaryContainer,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
