import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'api_service.dart';

/// Manages authentication state and user profile.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && ApiService.isLoggedIn;

  /// Initialize – load saved token & user data.
  Future<bool> initialize() async {
    await ApiService.loadToken();
    if (!ApiService.isLoggedIn) return false;

    // Try loading cached user data
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _currentUser = _parseUser(jsonDecode(userData));
    }

    // Verify token is still valid
    try {
      final response = await ApiService.get('/me');
      if (response['success'] == true) {
        _currentUser = _parseUser(response['data']);
        await prefs.setString('user_data', jsonEncode(response['data']));
        return true;
      }
    } catch (_) {
      // Token expired
      await logout();
    }
    return false;
  }

  /// Login with email/password.
  Future<UserProfile> login(String email, String password) async {
    final response = await ApiService.post('/login', {
      'email': email,
      'password': password,
    });

    final data = response['data'];
    await ApiService.saveToken(data['token']);
    _currentUser = _parseUser(data['user']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(data['user']));

    return _currentUser!;
  }

  /// Register a new account.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? studentNisn,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'role': role,
      if (studentNisn != null && studentNisn.isNotEmpty)
        'student_nisn': studentNisn,
    };

    final response = await ApiService.post('/register', body);
    return response['success'] == true;
  }

  /// Logout.
  Future<void> logout() async {
    try {
      await ApiService.post('/logout', {});
    } catch (_) {
      // Ignore if server is unreachable
    }
    _currentUser = null;
    await ApiService.clearToken();
  }

  UserProfile _parseUser(Map<String, dynamic> data) {
    UserRole role;
    switch (data['role']) {
      case 'superadmin':
        role = UserRole.superadmin;
        break;
      case 'wali_kelas':
        role = UserRole.waliKelas;
        break;
      case 'guru':
        role = UserRole.guru;
        break;
      default:
        role = UserRole.parent;
    }

    return UserProfile(
      name: data['name'],
      role: role,
      childStudentId: data['student_id'],
      homeroomClassName: data['homeroom_class_name'],
    );
  }
}
