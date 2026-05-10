import 'package:flutter/material.dart';

import 'account_management_screen.dart';
import '../services/api_service.dart';
import '../theme/rekap_theme.dart';
import '../widgets/loading_indicator.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _classrooms = [];
  List<dynamic> _students = [];
  List<dynamic> _accounts = [];
  List<dynamic> _subjects = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final subjectRes = await ApiService.get('/subjects');

      if (mounted) {
        setState(() {
          _classrooms = classRes['data'] ?? [];
          _students = studRes['data'] ?? [];
          _accounts = (accRes['data'] as List? ?? [])
              .where((a) => a['role'] == 'guru' || a['role'] == 'wali_kelas')
              .toList();
          _subjects = subjectRes['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
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
                decoration: const InputDecoration(
                  labelText: 'Nama Kelas',
                  hintText: 'Contoh: 10-A IPA',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _accounts.any((a) => a['id'] == selectedWaliKelasId)
                    ? selectedWaliKelasId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Wali Kelas (Guru)',
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('-- Belum Ditentukan --'),
                  ),
                  ..._accounts.map(
                    (a) => DropdownMenuItem<int>(
                      value: a['id'],
                      child: Text(a['name']),
                    ),
                  ),
                ],
                onChanged: (val) =>
                    setStateBuilder(() => selectedWaliKelasId = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama kelas harus diisi')),
                  );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data kelas berhasil disimpan')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete('/classrooms/$id');
        _loadData();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  value: _classrooms.any((c) => c['name'] == selectedClass)
                      ? selectedClass
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    helperText: student != null
                        ? 'Kelas tidak dapat diubah di sini'
                        : null,
                  ),
                  items: _classrooms.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['name'],
                      child: Text(c['name']),
                    );
                  }).toList(),
                  onChanged: student == null
                      ? (val) => setStateBuilder(() => selectedClass = val)
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (nisnCtrl.text.isEmpty ||
                    nameCtrl.text.isEmpty ||
                    selectedClass == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data siswa berhasil disimpan')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete('/students/$id');
        _loadData();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showSubjectForm() async {
    final nameCtrl = TextEditingController();
    final iconCtrl = TextEditingController(text: 'book');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Mata Pelajaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Mata Pelajaran',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconCtrl,
              decoration: const InputDecoration(
                labelText: 'Icon (opsional)',
                hintText: 'book',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama mata pelajaran harus diisi'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, {
                'name': nameCtrl.text.trim(),
                'icon': iconCtrl.text.trim().isEmpty
                    ? 'book'
                    : iconCtrl.text.trim(),
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await ApiService.post('/subjects', result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mata pelajaran berhasil ditambahkan'),
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteSubject(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mata Pelajaran'),
        content: const Text('Yakin ingin menghapus mata pelajaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete('/subjects/$id');
        _loadData();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _openAccountManagement() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AccountManagementScreen()));
  }

  Future<List<Map<String, dynamic>>?> _showAssignmentSelection(
    Map<String, dynamic> account,
  ) async {
    // Current assignments from account data
    final currentAssignments = (account['subjects'] as List? ?? []).map((s) {
      return {
        'subject_id': s['id'] as int,
        'subject_name': s['name'] as String,
        'classroom_id': s['pivot']?['classroom_id'] as int?,
      };
    }).toList();

    List<Map<String, dynamic>> selectedAssignments = List.from(currentAssignments);

    int? pendingSubjectId;
    int? pendingClassroomId;

    return showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Atur Penugasan: ${account['name']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Daftar Penugasan Aktif',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (selectedAssignments.isEmpty)
                    const Text(
                      'Belum ada penugasan.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ...selectedAssignments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final assign = entry.value;
                    
                    final subject = _subjects.firstWhere(
                      (s) => s['id'].toString() == assign['subject_id'].toString(),
                      orElse: () => {'name': 'Unknown Subject'},
                    );
                    final classroom = _classrooms.firstWhere(
                      (c) => c['id'].toString() == assign['classroom_id'].toString(),
                      orElse: () => {'name': 'Semua Kelas'},
                    );
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        subject['name'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Kelas: ${classroom['name']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: RekapTheme.error, size: 20),
                        onPressed: () {
                          setDialogState(() {
                            selectedAssignments.removeAt(index);
                          });
                        },
                      ),
                    );
                  }),
                  const Divider(height: 32),
                  const Text(
                    'Tambah Penugasan Baru',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: pendingSubjectId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Mata Pelajaran',
                      border: OutlineInputBorder(),
                    ),
                    items: _subjects.map((s) {
                      return DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text(s['name']),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => pendingSubjectId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: pendingClassroomId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Kelas',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Semua Kelas (Global)'),
                      ),
                      ..._classrooms.map((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name']),
                        );
                      }),
                    ],
                    onChanged: (val) => setDialogState(() => pendingClassroomId = val),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (pendingSubjectId == null)
                          ? null
                          : () {
                              setDialogState(() {
                                selectedAssignments.add({
                                  'subject_id': pendingSubjectId!,
                                  'classroom_id': pendingClassroomId!,
                                });
                                pendingSubjectId = null;
                                pendingClassroomId = null;
                              });
                            },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah ke Daftar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (pendingSubjectId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Data belum ditambahkan, tambahkan terlebih dahulu dengan klik "Tambah ke daftar"',
                      ),
                      backgroundColor: RekapTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, selectedAssignments);
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateGuruAssignments(Map<String, dynamic> account) async {
    final selectedAssignments = await _showAssignmentSelection(account);
    if (selectedAssignments == null) return;

    try {
      await ApiService.put('/accounts/${account['id']}/assignments', {
        'assignments': selectedAssignments.map((a) => {
          'subject_id': a['subject_id'],
          'classroom_id': a['classroom_id'],
        }).toList(),
        'classroom_ids': selectedAssignments.map((a) => a['classroom_id']).whereType<int>().toSet().toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penugasan guru berhasil diperbarui')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui penugasan: $e')),
        );
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
            Tab(text: 'Guru'),
            Tab(text: 'Mata Pelajaran'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator()
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
                      final waliKelasName =
                          c['wali_kelas']?['name'] ?? 'Belum ditentukan';
                      return Card(
                        child: ListTile(
                          title: Text(
                            c['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Wali Kelas: $waliKelasName'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: RekapTheme.primary,
                                ),
                                onPressed: () => _showClassForm(classroom: c),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: RekapTheme.error,
                                ),
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
                          leading: CircleAvatar(
                            child: Text(s['name'][0].toUpperCase()),
                          ),
                          title: Text(
                            s['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${s['nisn']} • Kelas: ${s['class_name']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: RekapTheme.primary,
                                ),
                                onPressed: () => _showStudentForm(student: s),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: RekapTheme.error,
                                ),
                                onPressed: () => _deleteStudent(s['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Tab Guru
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _accounts.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return Card(
                          child: ListTile(
                            title: const Text(
                              'Kelola Akun Guru',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Konfirmasi, assign, dan hapus akun guru/wali kelas',
                            ),
                            trailing: FilledButton(
                              onPressed: _openAccountManagement,
                              child: const Text('Kelola'),
                            ),
                          ),
                        );
                      }

                      final account = _accounts[i - 1];
                      final roleLabel = account['role'] == 'wali_kelas'
                          ? 'Wali Kelas'
                          : 'Guru Mata Pelajaran';
                      final subjects = account['subjects'] as List? ?? [];
                      final classrooms = account['classrooms'] as List? ?? [];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Text(account['name'][0].toUpperCase()),
                                ),
                                title: Text(
                                  account['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(roleLabel),
                                    if (account['homeroom_class'] != null)
                                      Text(
                                        'Wali Kelas: ${account['homeroom_class']['name']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: RekapTheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.manage_accounts,
                                    color: RekapTheme.primary,
                                  ),
                                  onPressed: _openAccountManagement,
                                ),
                              ),
                              if (subjects.isNotEmpty || classrooms.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (subjects.isNotEmpty) ...[
                                        const Text(
                                          'Mapel:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: subjects.map((s) {
                                            final classroomId = s['pivot']?['classroom_id'];
                                            String label = s['name'];
                                            if (classroomId != null) {
                                              final cls = _classrooms.firstWhere(
                                                (c) => c['id'].toString() == classroomId.toString(),
                                                orElse: () => {'name': ''},
                                              );
                                              if (cls['name'].isNotEmpty) {
                                                label = "$label (${cls['name']})";
                                              }
                                            }
                                            return Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: RekapTheme.primaryFixed
                                                    .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                label,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: RekapTheme.primary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      if (classrooms.isNotEmpty) ...[
                                        const Text(
                                          'Kelas:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: classrooms
                                              .map(
                                                (c) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: RekapTheme
                                                        .tertiaryFixed
                                                        .withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    c['name'],
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          RekapTheme.tertiary,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.tonal(
                                  onPressed: () => _updateGuruAssignments(
                                    account as Map<String, dynamic>,
                                  ),
                                  child: const Text('Atur Penugasan'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Tab Mata Pelajaran
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _subjects.length,
                    itemBuilder: (ctx, i) {
                      final subject = _subjects[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.book)),
                          title: Text(
                            subject['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Icon: ${subject['icon'] ?? 'book'}'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: RekapTheme.error,
                            ),
                            onPressed: () => _deleteSubject(subject['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: RekapTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 0) {
              _addClass();
            } else if (_tabController.index == 1) {
              _showStudentForm();
            } else if (_tabController.index == 2) {
              _openAccountManagement();
            } else {
              _showSubjectForm();
            }
          },
          backgroundColor: RekapTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, size: 24),
        ),
      ),
    );
  }
}
