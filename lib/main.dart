import 'package:flutter/material.dart';

import 'data/rekap_repository.dart';

import 'screens/admin_dashboard_screen.dart';
import 'screens/discipline_management_screen.dart';
import 'screens/discipline_screen.dart';
import 'screens/grade_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/parent_home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/student_list_screen.dart';
import 'screens/news_detail_screen.dart';
import 'services/auth_service.dart';
import 'theme/rekap_theme.dart';
import 'widgets/loading_indicator.dart';

import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
              LoadingIndicator(size: 40),
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
  State<AppShell> createState() => AppShellState();
}

/// Public state class for AppShell to allow tab switching from child screens
class AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Switch to a specific tab (for navigation from child screens)
  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  bool _hasShownInterstitial = false;

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await RekapRepository.instance.loadAll();
    if (mounted) {
      setState(() => _isLoading = false);
      _showInterstitialIfNeeded();
    }
  }

  void _showInterstitialIfNeeded() {
    if (_hasShownInterstitial) return;
    
    final repo = RekapRepository.instance;
    if (repo.schoolNews.isEmpty) return;
    
    // Get the absolute newest announcement
    final newest = repo.schoolNews.first;

    // Only show if the newest one has an image
    if (newest.imageUrl != null && newest.imageUrl!.isNotEmpty) {
      _hasShownInterstitial = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showAnnouncementDialog(newest);
        }
      });
    }
  }

  void _showAnnouncementDialog(latest) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Section
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            latest.fullImageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment(latest.focalX, latest.focalY),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            left: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: RekapTheme.secondary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'PENGUMUMAN BARU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Text Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latest.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: RekapTheme.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          latest.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: RekapTheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NewsDetailScreen(news: latest),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: RekapTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Lihat Detail',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            DisciplineManagementScreen(onRefresh: _refreshData),
            ProfileScreen(onLogout: widget.onLogout, onRefresh: _refreshData),
          ]
        : <Widget>[
            ParentHomeScreen(onRefresh: _refreshData),
            GradeDetailScreen(onRefresh: _refreshData),
            DisciplineScreen(onRefresh: _refreshData),
            ProfileScreen(onLogout: widget.onLogout, onRefresh: _refreshData),
          ];

    final navItems = (isAdmin || isGuru)
        ? const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Siswa'),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user),
              label: 'Tatib',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ]
        : const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Nilai',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user),
              label: 'Tatib',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ];

    // Clamp index
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: _isLoading
          ? const LoadingIndicator()
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
