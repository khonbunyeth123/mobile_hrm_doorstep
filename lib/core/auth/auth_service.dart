import 'token_storage.dart';

class AuthService {
  static Future<bool> isLoggedIn() => TokenStorage.isLoggedIn();

  static Future<String> currentRole() async {
    return (await TokenStorage.readRole()) ?? 'employee';
  }

  static Future<void> logout() => TokenStorage.clear();
}
