import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'api_client.dart';

class ApiSession {
  ApiSession._();

  static const _baseUrlKey = 'api_base_url';
  static const _tokenKey = 'api_access_token';
  static const _deviceIdKey = 'device_id';
  static const _emailKey = 'api_email';
  static const _accountScopeKey = 'api_account_scope';
  static const defaultBaseUrl = 'https://erp.puniterp.com/api/v1';

  static Future<String> baseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
  }

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> email() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String> accountScope() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accountScopeKey) ?? 'signed-out';
    } catch (_) {
      // Pure Dart repository tests do not initialize Flutter platform channels.
      return 'signed-out';
    }
  }

  static Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null) return existing;
    final id = const Uuid().v7();
    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  static Future<ApiClient?> client() async {
    final savedToken = await token();
    if (savedToken == null || savedToken.isEmpty) return null;
    return ApiClient(baseUrl: await baseUrl(), token: savedToken);
  }

  static Future<ApiClient> login({
    required String baseUrl,
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final normalized = _normalizeBaseUrl(
      baseUrl.isEmpty ? defaultBaseUrl : baseUrl,
    );
    final client = ApiClient(baseUrl: normalized);
    final response = await client.post(
      '/auth/login',
      data: {
        'login': email,
        'email': email,
        'password': password,
        'device_name': deviceName,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final user = data['user'] as Map<String, dynamic>? ?? const {};
    final accountKey = user['appUsername']?.toString().trim().isNotEmpty == true
        ? user['appUsername'].toString()
        : email;
    final tenantId = user['tenantId']?.toString().trim();
    final userId = user['id']?.toString().trim();
    final accountScope =
        tenantId != null &&
            tenantId.isNotEmpty &&
            userId != null &&
            userId.isNotEmpty
        ? '$tenantId:$userId'
        : '${normalized.toLowerCase()}:${accountKey.toLowerCase()}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_emailKey, accountKey);
    await prefs.setString(_accountScopeKey, accountScope);
    await deviceId();

    return ApiClient(baseUrl: normalized, token: accessToken);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_accountScopeKey);
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/api/v1')) return trimmed;
    return '$trimmed/api/v1';
  }
}
