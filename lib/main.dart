import 'package:flutter/material.dart';

import 'data/rekap_repository.dart';

import 'screens/admin_dashboard_screen.dart';
import 'screens/discipline_screen.dart';
import 'screens/grade_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/parent_home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/student_list_screen.dart';
import 'services/auth_service.dart';
import 'theme/rekap_theme.dart';

import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const RekapApp());
}

class RekapApp extends StatelessWidget {
  const RekapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REKAPAF',
      debugShowCheckedModeBanner: false,
      theme: RekapTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

/// AuthGate — decides whether to show login or the app shell.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await AuthService.instance.initialize();
    if (loggedIn) {
      await RekapRepository.instance.loadAll();
    }
    setState(() {
      _isLoggedIn = loggedIn;
      _isCheckingAuth = false;
    });
  }

  void _onLoginSuccess() async {
    setState(() => _isCheckingAuth = true);
    await RekapRepository.instance.loadAll();
    setState(() {
      _isLoggedIn = true;
      _isCheckingAuth = false;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAF8),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: RekapTheme.primary),
              SizedBox(height: 16),
              Text(
                'Memuat REKAPAF...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: RekapTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    return AppShell(onLogout: _onLogout);
  }
}

/// App Shell — Bottom navigation with role-based tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await RekapRepository.instance.loadAll();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository.instance;
    final user = repo.currentUser;
    final isAdmin = user.isAdmin;
    final isGuru = user.isGuru;

    final screens = (isAdmin || isGuru)
        ? <Widget>[
            AdminDashboardScreen(onRefresh: _refreshData),
            StudentListScreen(onRefresh: _refreshData),
            ProfileScreen(
              onLogout: widget.onLogout,
              onRefresh: _refreshData,
            ),
          ]
        : <Widget>[
            ParentHomeScreen(onRefresh: _refreshData),
            GradeDetailScreen(onRefresh: _refreshData),
            DisciplineScreen(onRefresh: _refreshData),
            ProfileScreen(
              onLogout: widget.onLogout,
              onRefresh: _refreshData,
            ),
          ];

    final navItems = (isAdmin || isGuru)
        ? const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Siswa'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ]
        : const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Nilai'),
            BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'Disiplin'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ];

    // Clamp index
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RekapTheme.primary))
          : IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: RekapTheme.primary,
        unselectedItemColor: RekapTheme.outline,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
        ),
        items: navItems,
      ),
    );
  }
}
