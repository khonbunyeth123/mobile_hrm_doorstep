import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'hrm_auth_token';
  static const _roleKey = 'hrm_auth_role';
  static const _userIdKey = 'hrm_auth_user_id';

  static const _prefsTokenKey = 'token';
  static const _prefsRoleKey = 'role';
  static const _prefsUserIdKey = 'user_id';
  static const _prefsIsLoggedInKey = 'isLoggedIn';

  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> saveSession({
    required String token,
    required String role,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      if (token.isNotEmpty) {
        await _secureStorage.write(key: _tokenKey, value: token);
      } else {
        await _secureStorage.delete(key: _tokenKey);
      }
      await _secureStorage.write(key: _roleKey, value: role);
      if (userId != null) {
        await _secureStorage.write(key: _userIdKey, value: userId.toString());
      }
    } catch (_) {
      // Fallback to SharedPreferences if secure storage is unavailable.
    }

    await prefs.setString(_prefsTokenKey, token);
    await prefs.setString(_prefsRoleKey, role);
    if (userId != null) {
      await prefs.setInt(_prefsUserIdKey, userId);
    }
    await prefs.setBool(_prefsIsLoggedInKey, token.isNotEmpty);
  }

  static Future<String?> readToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsTokenKey);
  }

  static Future<String?> readRole() async {
    try {
      final role = await _secureStorage.read(key: _roleKey);
      if (role != null && role.isNotEmpty) return role;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsRoleKey);
  }

  static Future<int?> readUserId() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      if (userId != null && userId.isNotEmpty) {
        return int.tryParse(userId);
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsUserIdKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _roleKey);
      await _secureStorage.delete(key: _userIdKey);
    } catch (_) {}

    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsRoleKey);
    await prefs.remove(_prefsUserIdKey);
    await prefs.setBool(_prefsIsLoggedInKey, false);
  }
}
