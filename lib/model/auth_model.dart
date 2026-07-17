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
    this.isVerified,
    this.isDocumentsVerified,
  });

  final bool success;
  final String message;
  final String? token;
  final String? driverId;
  final String? email;
  final String? username;
  final String? phoneNumber;
  final bool? isVerified;
  final bool? isDocumentsVerified;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    print('AuthResponse.fromJson: json=$json, data=$data');
    return AuthResponse(
      success: json['success'] == true,
      message: (json['message'] as String?) ?? 'Unknown response',
      token: data?['token'] as String?,
      driverId: data?['driverId'] as String?,
      email: data?['email'] as String?,
      username: data?['username'] as String?,
      phoneNumber: data?['phoneNumber'] as String?,
      isVerified: data?['isVerified'] as bool?,
      isDocumentsVerified: data?['isDocumentsVerified'] as bool?,
    );
  }
}

class AuthRegistorModel {
  AuthRegistorModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.gender,
    required this.fcmToken,
    required this.deviceId,
  });

  String firstName;
  String lastName;
  String email;
  String phone;
  String password;
  String gender;
  String fcmToken;
  String deviceId;

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phone": phone,
      "password": password,
      "gender": gender,
      "fcmToken": fcmToken,
      "deviceId": deviceId,
    };
  }
}

class AuthRegistorResponse {
  AuthRegistorResponse({
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

  factory AuthRegistorResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return AuthRegistorResponse(
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
