enum AuthStep { login, verifyOtp, success }

class AuthModel {
  AuthModel({this.phoneNumber = '', this.otp = ''});

  String phoneNumber;
  String otp;
}

class AuthResponse {
  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.driverId,
    this.email,
    this.username,
    this.phoneNumber,
  });

  final bool success;
  final String message;
  final String? token;
  final String? driverId;
  final String? email;
  final String? username;
  final String? phoneNumber;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return AuthResponse(
      success: json['success'] == true,
      message: (json['message'] as String?) ?? 'Unknown response',
      token: data?['token'] as String?,
      driverId: data?['driverId'] as String?,
      email: data?['email'] as String?,
      username: data?['username'] as String?,
      phoneNumber: data?['phoneNumber'] as String?,
    );
  }
}
