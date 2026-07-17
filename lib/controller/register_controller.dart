import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:swiftbike_driver/model/auth_model.dart';
import 'package:swiftbike_driver/service/auth_service.dart';
import 'package:swiftbike_driver/view/document_verification_view.dart';

enum RegisterGender { male, female, other }

extension RegisterGenderX on RegisterGender {
  String get apiValue => switch (this) {
    RegisterGender.male => 'MALE',
    RegisterGender.female => 'FEMALE',
    RegisterGender.other => 'OTHER',
  };

  String get label => switch (this) {
    RegisterGender.male => 'Male',
    RegisterGender.female => 'Female',
    RegisterGender.other => 'Other',
  };
}

class RegisterController extends ChangeNotifier {
  RegisterController();

  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String password = '';
  RegisterGender? gender;

  AuthService _authService = AuthService();

  bool isLoading = false;
  String? message;
  bool success = false;

  // Response fields carried forward after successful registration
  String? token;
  String? driverId;
  String? username;
  String? phoneNumber;

  void updateFirstName(String v) {
    firstName = v;
    notifyListeners();
  }

  void updateLastName(String v) {
    lastName = v;
    notifyListeners();
  }

  void updateEmail(String v) {
    email = v;
    notifyListeners();
  }

  void updatePhone(String v) {
    phone = v;
    notifyListeners();
  }

  void updatePassword(String v) {
    password = v;
    notifyListeners();
  }

  void updateGender(RegisterGender v) {
    gender = v;
    notifyListeners();
  }

  String? validate() {
    if (firstName.trim().isEmpty) return 'First name is required';
    if (lastName.trim().isEmpty) return 'Last name is required';
    if (email.trim().isEmpty || !email.contains('@')) {
      return 'Enter a valid email';
    }
    if (phone.trim().length < 10) return 'Enter a valid phone number';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (gender == null) return 'Please select a gender';
    return null;
  }

  Future<void> submitRegister() async {
    final validationError = validate();
    if (validationError != null) {
      message = validationError;
      notifyListeners();
      return;
    }

    isLoading = true;
    message = null;
    notifyListeners();

    try {
      // TODO: fetch real values from your FCM / device-info services
      const fcmToken = 'TODO_FCM_TOKEN';
      const deviceId = 'TODO_DEVICE_ID';

      final payload = AuthRegistorModel(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
        gender: gender!.apiValue,
        fcmToken: fcmToken,
        deviceId: deviceId,
      );

      // TODO: replace with your actual service call, e.g.:
      // final response = await _authService.register(payload);
      // // final response = await _mockRegisterCall(payload);

      // success = response.success;
      // message = response.message;
      // token = response.token;
      // driverId = response.driverId;
      // username = response.username;
      // phoneNumber = response.phoneNumber;
    } catch (e) {
      success = false;
      message = 'Registration failed. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    password = '';
    gender = null;
    isLoading = false;
    message = null;
    success = false;
    token = null;
    driverId = null;
    username = null;
    phoneNumber = null;
    notifyListeners();
  }
}
