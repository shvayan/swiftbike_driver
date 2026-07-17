import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/auth_model.dart';
import 'http_middleware.dart';

class AuthService {
  AuthService({http.Client? client, String? Function()? tokenProvider})
    : _client = client ?? http.Client(),
      _middleware = HttpMiddleware(tokenProvider: tokenProvider);

  final http.Client _client;
  final HttpMiddleware _middleware;

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://13.140.142.12:8081/',
  );

  Uri _buildUri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedBaseUrl).resolve(path);
  }

  Future<AuthResponse> login(String phoneNumber) async {
    final response = await _client.post(
      _buildUri('api/v1/driver/auth/login'),
      headers: _middleware.apply(),
      body: jsonEncode(<String, dynamic>{'emailOrPhone': phoneNumber}),
    );

    return _parseResponse(response);
  }

  Future<AuthRegistorResponse> register(AuthRegistorModel model) async {
    final response = await _client.post(
      _buildUri('api/v1/driver/auth/register'),
      headers: _middleware.apply(),
      body: jsonEncode(model.toJson()),
    );

    return _parseRegistorResponse(response);
  }

  Future<AuthResponse> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await _client.post(
      _buildUri('api/v1/driver/auth/verify-otp'),
      headers: _middleware.apply(),
      body: jsonEncode(<String, dynamic>{
        'emailOrPhone': phoneNumber,
        'otp': otp,
      }),
    );

    return _parseResponse(response);
  }

  AuthResponse _parseResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthResponse.fromJson(decoded);
  }

  AuthRegistorResponse _parseRegistorResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthRegistorResponse.fromJson(decoded);
  }
}
