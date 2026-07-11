import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  AuthSession({required this.token, required this.driverId});

  final String token;
  final String driverId;
}

class AuthSessionService {
  static const String _tokenKey = 'driver_auth_token';
  static const String _driverIdKey = 'driver_auth_driver_id';

  Future<void> saveSession({
    required String token,
    required String driverId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_driverIdKey, driverId);
  }

  Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final driverId = prefs.getString(_driverIdKey);

    if (token == null ||
        token.isEmpty ||
        driverId == null ||
        driverId.isEmpty) {
      return null;
    }

    return AuthSession(token: token, driverId: driverId);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_driverIdKey);
  }
}
