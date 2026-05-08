import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central API service for all HTTP calls to the Laravel backend.
class ApiService {
  // Gunakan 10.0.2.2 untuk Android Emulator, atau IP lokal untuk device fisik.
  // Ganti dengan IP komputer kamu di jaringan lokal.
  static const String baseUrl = 'https://ca32-2001-448a-5130-bac1-700d-50bd-ce17-ef14.ngrok-free.app/api';

  static String? _token;

  /// Set the base URL dynamically (for device testing).
  static String _currentBaseUrl = baseUrl;

  static void setBaseUrl(String url) {
    _currentBaseUrl = url;
  }

  static String get currentBaseUrl => _currentBaseUrl;

  // ── Token Management ──────────────────────────────────────────────────

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ── HTTP Helpers ──────────────────────────────────────────────────────

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_currentBaseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_currentBaseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$_currentBaseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$_currentBaseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields,
    File? file,
    String fileField,
  ) async {
    final uri = Uri.parse('$_currentBaseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });
    
    request.fields.addAll(fields);
    
    if (file != null) {
      final mimeTypeData = lookupMimeType(file.path, headerBytes: [0xFF, 0xD8])?.split('/');
      final multipartFile = await http.MultipartFile.fromPath(
        fileField,
        file.path,
        contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
      );
      request.files.add(multipartFile);
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Validation errors
    if (response.statusCode == 422) {
      final errors = body['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      final message = firstError is List
          ? firstError.first
          : body['message'] ?? 'Validation error';
      throw ApiException(message.toString(), response.statusCode);
    }

    // Auth errors
    if (response.statusCode == 401) {
      throw ApiException('Sesi telah berakhir. Silakan login kembali.', 401);
    }

    throw ApiException(
      body['message']?.toString() ?? 'Terjadi kesalahan server',
      response.statusCode,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
