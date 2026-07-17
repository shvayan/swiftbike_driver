import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  AuthSession({
    required this.token,
    required this.driverId,
    required this.isDriverVerified,
    required this.isDriverDocumentsVerified,
  });

  final String token;
  final String driverId;
  final bool isDriverVerified;
  final bool isDriverDocumentsVerified;

  AuthSession copyWith({
    String? token,
    String? driverId,
    bool? isDriverVerified,
    bool? isDriverDocumentsVerified,
  }) {
    return AuthSession(
      token: token ?? this.token,
      driverId: driverId ?? this.driverId,
      isDriverVerified: isDriverVerified ?? this.isDriverVerified,
      isDriverDocumentsVerified:
          isDriverDocumentsVerified ?? this.isDriverDocumentsVerified,
    );
  }
}

class AuthSessionService {
  static const String _tokenKey = 'driver_auth_token';
  static const String _driverIdKey = 'driver_auth_driver_id';
  static const String _isVerifiedKey = 'driver_auth_is_verified';
  static const String _isDocumentsVerifiedKey =
      'driver_auth_is_documents_verified';

  Future<void> saveSession({
    required String token,
    required String driverId,
    required bool isDriverVerified,
    required bool isDriverDocumentsVerified,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_driverIdKey, driverId);
    await prefs.setBool(_isVerifiedKey, isDriverVerified);
    await prefs.setBool(_isDocumentsVerifiedKey, isDriverDocumentsVerified);
  }

  /// Call this after document verification status changes (e.g. admin
  /// approves docs and the app re-checks status) without a full re-login.
  Future<void> updateDocumentsVerified(bool isDriverDocumentsVerified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDocumentsVerifiedKey, isDriverDocumentsVerified);
  }

  Future<void> updateDriverVerified(bool isDriverVerified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isVerifiedKey, isDriverVerified);
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

    return AuthSession(
      token: token,
      driverId: driverId,
      isDriverVerified: prefs.getBool(_isVerifiedKey) ?? false,
      isDriverDocumentsVerified:
          prefs.getBool(_isDocumentsVerifiedKey) ?? false,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_driverIdKey);
    await prefs.remove(_isVerifiedKey);
    await prefs.remove(_isDocumentsVerifiedKey);
  }
}
