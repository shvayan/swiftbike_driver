import 'package:flutter/material.dart';
import 'package:swiftbike_driver/core/colors/app_colors.dart';

import '../controller/auth_controller.dart';
import '../model/auth_model.dart';
import '../controller/trip_request_controller.dart';
import 'trip_request_view.dart';

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

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Driver Login'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final controller = widget.controller;

          if (controller.step == AuthStep.success &&
              !_hasNavigatedToDriverLead) {
            _hasNavigatedToDriverLead = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => TripRequestView(
                    controller: TripRequestController(
                      token: controller.token,
                      driverId: controller.driverId,
                      vehicleType: 'BIKE',
                      driverStatus: 'ONLINE',
                    ),
                  ),
                ),
              );
            });
          }

          if (controller.step != AuthStep.success) {
            _hasNavigatedToDriverLead = false;
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.step == AuthStep.login
                              ? 'Welcome back'
                              : controller.step == AuthStep.verifyOtp
                              ? 'Verify OTP'
                              : 'Signed in',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.step == AuthStep.login
                              ? 'Enter your phone number to continue.'
                              : controller.step == AuthStep.verifyOtp
                              ? 'Enter the OTP sent to your phone.'
                              : 'Login completed successfully.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (controller.step == AuthStep.login) ...[
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: controller.updatePhoneNumber,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: controller.isLoading
                                ? null
                                : () async {
                                    controller.updatePhoneNumber(
                                      _phoneController.text,
                                    );
                                    await controller.submitLogin();
                                  },
                            child: controller.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ] else if (controller.step == AuthStep.verifyOtp) ...[
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'OTP',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: controller.updateOtp,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: controller.isLoading
                                ? null
                                : () async {
                                    controller.updateOtp(_otpController.text);
                                    await controller.submitOtp();
                                  },
                            child: controller.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify OTP'),
                          ),
                          TextButton(
                            onPressed: controller.isLoading
                                ? null
                                : () {
                                    controller.reset();
                                    _otpController.clear();
                                  },
                            child: const Text('Change phone number'),
                          ),
                        ] else ...[
                          if (controller.email != null)
                            Text('Email: ${controller.email}'),
                          if (controller.username != null)
                            Text('Username: ${controller.username}'),
                          if (controller.driverId != null)
                            Text('Driver ID: ${controller.driverId}'),
                          if (controller.token != null) ...[
                            const SizedBox(height: 8),
                            const Text('Token received successfully.'),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: controller.reset,
                            child: const Text('Back to login'),
                          ),
                        ],
                        if (controller.message != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            controller.message!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
