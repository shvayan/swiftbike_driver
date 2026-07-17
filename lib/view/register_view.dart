import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../controller/register_controller.dart';
import '../controller/trip_request_controller.dart';
import 'trip_request_view.dart';

const _kPurple = Color(0xFF6C5CE7);
const _kPurpleDark = Color(0xff6C4CF1);
const _kAmber = Color(0xff6C4CF1);
const _kInputFill = Color(0xFFF3F3F7);
const _kTextDark = Color(0xFF2D2D3A);
const _kTextMuted = Color(0xFF9B9BAB);

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final RegisterController _controller;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = RegisterController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPurple,
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.success && !_hasNavigated) {
            _hasNavigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => TripRequestView(
                    controller: TripRequestController(
                      token: _controller.token,
                      driverId: _controller.driverId,
                      vehicleType: 'BIKE',
                      driverStatus: 'ONLINE',
                    ),
                  ),
                ),
              );
            });
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
                          _RegisterHero(
                            onBack: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                28,
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
                              child: _RegisterForm(
                                controller: _controller,
                                firstNameController: _firstNameController,
                                lastNameController: _lastNameController,
                                emailController: _emailController,
                                phoneController: _phoneController,
                                passwordController: _passwordController,
                                obscurePassword: _obscurePassword,
                                onTogglePassword: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                onSubmit: () async {
                                  _controller.updateFirstName(
                                    _firstNameController.text,
                                  );
                                  _controller.updateLastName(
                                    _lastNameController.text,
                                  );
                                  _controller.updateEmail(
                                    _emailController.text,
                                  );
                                  _controller.updatePhone(
                                    _phoneController.text,
                                  );
                                  _controller.updatePassword(
                                    _passwordController.text,
                                  );
                                  await _controller.submitRegister();
                                },
                                onLoginTap: () => Navigator.of(context).pop(),
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
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onBack,
            child: Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: _kAmber,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _kInputFill,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                  child: Center(
                    child: Container(
                      height: 68,
                      width: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kAmber.withOpacity(0.95),
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: _kInputFill,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sign up to start driving with SwiftBike',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.controller,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onLoginTap,
  });

  final RegisterController controller;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'First name',
                child: _AuthField(
                  controller: firstNameController,
                  hint: 'Taras',
                  onChanged: controller.updateFirstName,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Last name',
                child: _AuthField(
                  controller: lastNameController,
                  hint: 'Shevchenko',
                  onChanged: controller.updateLastName,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Email address',
          child: _AuthField(
            controller: emailController,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: controller.updateEmail,
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Phone number',
          child: _AuthField(
            controller: phoneController,
            hint: '98765 43210',
            keyboardType: TextInputType.phone,
            onChanged: controller.updatePhone,
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Password',
          child: _AuthField(
            controller: passwordController,
            hint: '••••••••',
            obscureText: obscurePassword,
            onChanged: controller.updatePassword,
            suffix: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: _kTextMuted,
              ),
              onPressed: onTogglePassword,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Gender',
          child: _GenderSelector(
            selected: controller.gender,
            onSelected: controller.updateGender,
          ),
        ),
        const SizedBox(height: 24),
        if (controller.message != null) ...[
          Text(
            controller.message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: controller.success
                  ? const Color(0xFF1FAE5C)
                  : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: controller.isLoading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: _kAmber,
              disabledBackgroundColor: _kAmber.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kPurpleDark,
                    ),
                  )
                : const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kInputFill,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            text: TextSpan(
              text: 'Already have an account? ',
              style: const TextStyle(fontSize: 13, color: _kTextMuted),
              children: [
                TextSpan(
                  text: 'Log In',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPurple,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onLoginTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _kTextDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _kInputFill,
        suffixIcon: suffix,
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

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.selected, required this.onSelected});

  final RegisterGender? selected;
  final ValueChanged<RegisterGender> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: RegisterGender.values.map((g) {
        final isSelected = selected == g;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: g != RegisterGender.values.last ? 8 : 0,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(g),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _kPurple : _kInputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  g.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _kTextDark,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
