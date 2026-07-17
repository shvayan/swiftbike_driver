import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:swiftbike_driver/view/document_verification_view.dart';
import 'package:swiftbike_driver/view/register_view.dart';

import '../controller/auth_controller.dart';
import '../model/auth_model.dart';
import '../controller/trip_request_controller.dart';
import 'trip_request_view.dart';

// Design tokens for this screen (matches the reference mock)
const _kPurple = Color(0xFF6C5CE7);
const _kPurpleDark = Color(0xff6C4CF1);
const _kAmber = Color(0xff6C4CF1);
const _kInputFill = Color(0xFFF3F3F7);
const _kTextDark = Color(0xFF2D2D3A);
const _kTextMuted = Color(0xFF9B9BAB);

class AuthView extends StatefulWidget {
  const AuthView({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _hasNavigatedToDriverLead = false;
  bool _obscure =
      false; // reserved for parity with design; phone/OTP fields don't need it

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPurple,
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final controller = widget.controller;

          if (controller.step == AuthStep.success &&
              !_hasNavigatedToDriverLead) {
            _hasNavigatedToDriverLead = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              final Widget destination =
                  (controller.isDriverVerified == true &&
                      controller.isDriverDocumentsVerified == false)
                  ? DocumentVerificationView(
                      token: controller.token,
                      driverId: controller.driverId,
                    )
                  : TripRequestView(
                      controller: TripRequestController(
                        token: controller.token,
                        driverId: controller.driverId,
                        vehicleType: 'BIKE',
                        driverStatus: 'ONLINE',
                      ),
                    );

              Navigator.of(
                context,
              ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
            });
          }

          if (controller.step != AuthStep.success) {
            _hasNavigatedToDriverLead = false;
          }

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _Hero(step: controller.step),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 0),
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                32,
                                24,
                                24,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  topRight: Radius.circular(32),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _buildStepContent(controller),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepContent(AuthController controller) {
    switch (controller.step) {
      case AuthStep.login:
        return _LoginStep(
          key: const ValueKey('login'),
          controller: _phoneController,
          isLoading: controller.isLoading,
          message: controller.message,
          onChanged: controller.updatePhoneNumber,
          onSubmit: () async {
            controller.updatePhoneNumber(_phoneController.text);
            await controller.submitLogin();
          },
        );
      case AuthStep.verifyOtp:
        return _OtpStep(
          key: const ValueKey('otp'),
          controller: _otpController,
          isLoading: controller.isLoading,
          message: controller.message,
          phoneNumber: _phoneController.text,
          onChanged: controller.updateOtp,
          onSubmit: () async {
            controller.updateOtp(_otpController.text);
            await controller.submitOtp();
          },
          onChangeNumber: () {
            controller.reset();
            _otpController.clear();
          },
        );
      case AuthStep.success:
        return _SuccessStep(
          key: const ValueKey('success'),
          email: controller.email,
          username: controller.username,
          driverId: controller.driverId,
          hasToken: controller.token != null,
          onBack: controller.reset,
        );
    }
  }
}

/// Purple header with illustration + back button, matching the mock's hero.
class _Hero extends StatelessWidget {
  const _Hero({required this.step});

  final AuthStep step;

  @override
  Widget build(BuildContext context) {
    final title = switch (step) {
      AuthStep.login => 'Let\'s get started!',
      AuthStep.verifyOtp => 'Verify your number',
      AuthStep.success => 'You\'re all set',
    };
    final showBack = step != AuthStep.login;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kPurple, _kPurpleDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBack)
                _CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () {
                    // Handled by step-specific back actions below
                  },
                )
              else
                const SizedBox(width: 40),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                _DriverBadge(),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative circle illustration stand-in (bike/rider icon on a soft disc).
class _DriverBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 130,
            width: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kAmber.withOpacity(0.95),
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              color: _kInputFill,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: const BoxDecoration(color: _kAmber, shape: BoxShape.circle),
        child: Icon(icon, color: _kPurpleDark, size: 20),
      ),
    );
  }
}

class _LoginStep extends StatelessWidget {
  const _LoginStep({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.message,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final String? message;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        _AuthField(
          controller: controller,
          hint: '98765 43210',
          keyboardType: TextInputType.phone,
          onChanged: onChanged,
        ),
        const SizedBox(height: 24),
        if (message != null) ...[
          _ErrorText(message: message!),
          const SizedBox(height: 12),
        ],
        _AmberButton(
          label: 'Continue',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'By continuing you agree to SwiftBike\'s Terms & Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _kTextMuted),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            text: TextSpan(
              text: 'Don\'t have an account? ',
              style: const TextStyle(fontSize: 13, color: _kTextMuted),
              children: [
                TextSpan(
                  text: 'Sign Up',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPurple,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterView()),
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.message,
    required this.phoneNumber,
    required this.onChanged,
    required this.onSubmit,
    required this.onChangeNumber,
  });

  final TextEditingController controller;
  final bool isLoading;
  final String? message;
  final String phoneNumber;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onChangeNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (phoneNumber.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Code sent to $phoneNumber',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kTextMuted),
            ),
          ),
        const Text(
          'OTP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        _AuthField(
          controller: controller,
          hint: '• • • • • •',
          keyboardType: TextInputType.number,
          maxLength: 6,
          letterSpacing: 6,
          onChanged: onChanged,
        ),
        const SizedBox(height: 24),
        if (message != null) ...[
          _ErrorText(message: message!),
          const SizedBox(height: 12),
        ],
        _AmberButton(
          label: 'Verify & Continue',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : onChangeNumber,
            style: TextButton.styleFrom(foregroundColor: _kPurple),
            child: const Text(
              'Change phone number',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({
    super.key,
    required this.email,
    required this.username,
    required this.driverId,
    required this.hasToken,
    required this.onBack,
  });

  final String? email;
  final String? username;
  final String? driverId;
  final bool hasToken;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFE7F8EE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF1FAE5C),
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        if (username != null) _InfoRow(label: 'Username', value: username!),
        if (email != null) _InfoRow(label: 'Email', value: email!),
        if (driverId != null) _InfoRow(label: 'Driver ID', value: driverId!),
        if (hasToken) _InfoRow(label: 'Session', value: 'Active'),
        const SizedBox(height: 24),
        _AmberButton(
          label: 'Back to login',
          isLoading: false,
          onPressed: onBack,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kTextMuted)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTextDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.maxLength,
    this.letterSpacing,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int? maxLength;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      textAlign: maxLength != null ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _kTextDark,
        letterSpacing: letterSpacing,
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: _kInputFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPurple, width: 1.5),
        ),
      ),
    );
  }
}

class _AmberButton extends StatelessWidget {
  const _AmberButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _kAmber,
          disabledBackgroundColor: _kAmber.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPurpleDark,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kInputFill,
                ),
              ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: Colors.redAccent),
    );
  }
}
