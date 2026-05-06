import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/rekap_theme.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _pendingAccounts = [];
  List<dynamic> _activeAccounts = [];
  List<dynamic> _subjects = [];
  List<dynamic> _classrooms = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final pendingRes = await ApiService.get('/accounts/pending');
      final activeRes = await ApiService.get('/accounts');
      final subjectsRes = await ApiService.get('/subjects');
      final classroomsRes = await ApiService.get('/classrooms');

      if (mounted) {
        setState(() {
          _pendingAccounts = pendingRes['data'] ?? [];
          _activeAccounts = activeRes['data'] ?? [];
          _subjects = subjectsRes['data'] ?? [];
          _classrooms = classroomsRes['data'] ?? [];
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

  Future<void> _approveAccount(dynamic account) async {
    Map<String, List<int>>? selectedAssignments;
    
    if (account['role'] == 'guru') {
      selectedAssignments = await _showAssignmentSelection(account);
      if (selectedAssignments == null) return;
    }

    try {
      await ApiService.post('/accounts/${account['id']}/approve', {
        if (selectedAssignments != null) 'subject_ids': selectedAssignments['subjects'],
        if (selectedAssignments != null) 'classroom_ids': selectedAssignments['classrooms'],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dikonfirmasi')),
        );
        _loadAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengkonfirmasi akun: $e')),
        );
      }
    }
  }

  Future<Map<String, List<int>>?> _showAssignmentSelection(dynamic account) async {
    final currentSubjectIds = (account['subjects'] as List? ?? []).map((s) => s['id'] as int).toList();
    final currentClassroomIds = (account['classrooms'] as List? ?? []).map((c) => c['id'] as int).toList();
    
    List<int> selectedSubjectIds = List.from(currentSubjectIds);
    List<int> selectedClassroomIds = List.from(currentClassroomIds);

    return showDialog<Map<String, List<int>>>(
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
                  const Text('Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._subjects.map((subject) {
                    final isSelected = selectedSubjectIds.contains(subject['id']);
                    return CheckboxListTile(
                      title: Text(subject['name']),
                      value: isSelected,
                      dense: true,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) selectedSubjectIds.add(subject['id']);
                          else selectedSubjectIds.remove(subject['id']);
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text('Kelas', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._classrooms.map((classroom) {
                    final isSelected = selectedClassroomIds.contains(classroom['id']);
                    return CheckboxListTile(
                      title: Text(classroom['name']),
                      value: isSelected,
                      dense: true,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) selectedClassroomIds.add(classroom['id']);
                          else selectedClassroomIds.remove(classroom['id']);
                        });
                      },
                    );
                  }),
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
              onPressed: () => Navigator.pop(ctx, {
                'subjects': selectedSubjectIds,
                'classrooms': selectedClassroomIds,
              }),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateGuruAssignments(dynamic account) async {
    final selectedAssignments = await _showAssignmentSelection(account);
    if (selectedAssignments == null) return;

    try {
      await ApiService.put('/accounts/${account['id']}/assignments', {
        'subject_ids': selectedAssignments['subjects'],
        'classroom_ids': selectedAssignments['classrooms'],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penugasan guru berhasil diperbarui')),
        );
        _loadAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui penugasan: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text('Apakah Anda yakin ingin menolak / menghapus akun ini?'),
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

    if (confirm != true) return;

    try {
      await ApiService.delete('/accounts/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dihapus')),
        );
        _loadAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus akun: $e')),
        );
      }
    }
  }

  Widget _buildAccountList(List<dynamic> accounts, bool isPending) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: RekapTheme.outline),
            const SizedBox(height: 16),
            Text(
              isPending ? 'Tidak ada akun yang menunggu konfirmasi.' : 'Tidak ada akun aktif.',
              style: const TextStyle(color: RekapTheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAccounts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final account = accounts[index];
          String role = 'User';
          if (account['role'] == 'wali_kelas') {
            role = 'Wali Kelas';
          } else if (account['role'] == 'parent') {
            role = 'Orang Tua';
          } else if (account['role'] == 'guru') {
            final hr = account['homeroom_class'];
            if (hr != null) {
              role = 'Guru & Wali Kelas ${hr['name']}';
            } else {
              role = 'Guru';
            }
          }
          
          final subjects = account['subjects'] as List? ?? [];
          final classrooms = account['classrooms'] as List? ?? [];
          
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: RekapTheme.primaryContainer,
                        child: Text(
                          account['name'][0].toString().toUpperCase(),
                          style: const TextStyle(color: RekapTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account['name'],
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              account['email'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: RekapTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: RekapTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (account['role'] == 'guru' && (subjects.isNotEmpty || classrooms.isNotEmpty)) ...[
                    const SizedBox(height: 12),
                    if (subjects.isNotEmpty) ...[
                      const Text(
                        'Mapel:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: subjects.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: RekapTheme.primaryFixed.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s['name'],
                            style: const TextStyle(fontSize: 11, color: RekapTheme.primary),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (classrooms.isNotEmpty) ...[
                      const Text(
                        'Kelas:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: classrooms.map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: RekapTheme.tertiaryFixed.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c['name'],
                            style: const TextStyle(fontSize: 11, color: RekapTheme.tertiary),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _deleteAccount(account['id']),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RekapTheme.error,
                          side: const BorderSide(color: RekapTheme.error),
                        ),
                        child: const Text('Hapus'),
                      ),
                      const SizedBox(width: 12),
                      if (isPending)
                        FilledButton(
                          onPressed: () => _approveAccount(account),
                          child: const Text('Konfirmasi'),
                        )
                      else if (account['role'] == 'guru')
                        FilledButton.tonal(
                          onPressed: () => _updateGuruAssignments(account),
                          child: const Text('Atur Penugasan'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RekapTheme.surface,
      appBar: AppBar(
        title: const Text('Kelola Akun'),
        backgroundColor: Colors.white,
        foregroundColor: RekapTheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: RekapTheme.primary,
          unselectedLabelColor: RekapTheme.onSurfaceVariant,
          indicatorColor: RekapTheme.primary,
          tabs: const [
            Tab(text: 'Menunggu Konfirmasi'),
            Tab(text: 'Akun Aktif'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAccountList(_pendingAccounts, true),
                _buildAccountList(_activeAccounts, false),
              ],
            ),
    );
  }
}
