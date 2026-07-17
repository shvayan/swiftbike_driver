import 'package:flutter/foundation.dart';

import '../model/auth_model.dart';
import '../service/auth_session_service.dart';
import '../service/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthService? service})
    : _service = service ?? AuthService(tokenProvider: () => _tokenForBoot);

  final AuthService _service;
  final AuthSessionService _sessionService = AuthSessionService();
  final AuthModel _model = AuthModel();

  static String? _tokenForBoot;

  AuthStep _step = AuthStep.login;
  bool _isLoading = false;
  String? _message;
  String? _token;
  String? _driverId;
  String? _email;
  String? _username;
  bool? isVerified;
  bool? isDocumentsVerified;

  AuthStep get step => _step;
  bool get isLoading => _isLoading;
  String? get message => _message;
  String? get token => _token;
  String? get driverId => _driverId;
  String? get email => _email;
  String? get username => _username;
  bool? get isDriverVerified => isVerified;
  bool? get isDriverDocumentsVerified => isDocumentsVerified;

  String get phoneNumber => _model.phoneNumber;
  String get otp => _model.otp;

  void updatePhoneNumber(String value) {
    _model.phoneNumber = value;
  }

  void updateOtp(String value) {
    _model.otp = value;
  }

  Future<void> submitLogin() async {
    if (_model.phoneNumber.trim().isEmpty) {
      _message = 'Enter a phone number';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final response = await _service.login(_model.phoneNumber.trim());
      _message = response.message;
      if (response.success) {
        _step = AuthStep.verifyOtp;
      }
    } catch (error) {
      _message = 'Login failed: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitOtp() async {
    if (_model.otp.trim().isEmpty) {
      _message = 'Enter the OTP';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final response = await _service.verifyOtp(
        phoneNumber: _model.phoneNumber.trim(),
        otp: _model.otp.trim(),
      );
      _message = response.message;
      if (response.success) {
        _step = AuthStep.success;
        _token = response.token;
        _tokenForBoot = response.token;
        _driverId = response.driverId;
        _email = response.email;
        _username = response.username;
        isVerified = response.isVerified;
        isDocumentsVerified = response.isDocumentsVerified;

        if (_token != null && _driverId != null) {
          await AuthSessionService().saveSession(
            token: token!,
            driverId: driverId!,
            isDriverVerified: isVerified ?? false,
            isDriverDocumentsVerified: isDocumentsVerified ?? false,
          );
        }
      }
    } catch (error) {
      _message = 'OTP verification failed: $error';
    } finally {
      _setLoading(false);
    }
  }

  void reset() {
    _model.phoneNumber = '';
    _model.otp = '';
    _step = AuthStep.login;
    _message = null;
    _token = null;
    _tokenForBoot = null;
    _driverId = null;
    _email = null;
    _username = null;
    _sessionService.clearSession();
    notifyListeners();
  }

  void clearSession() {
    _token = null;
    _tokenForBoot = null;
  }

  Future<AuthSession?> loadSavedSession() async {
    return _sessionService.loadSession();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
