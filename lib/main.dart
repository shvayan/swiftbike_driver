import 'package:flutter/material.dart';

import 'controller/auth_controller.dart';
import 'controller/trip_request_controller.dart';
import 'service/auth_session_service.dart';
import 'view/trip_request_view.dart';
import 'view/auth_view.dart';
import 'view/document_verification_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthController _controller;
  late final Future<AuthSession?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _controller = AuthController();
    _sessionFuture = _controller.loadSavedSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwiftBike Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: FutureBuilder<AuthSession?>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data;

          if (session == null) {
            return AuthView(controller: _controller);
          }

          if (session.isDriverVerified && !session.isDriverDocumentsVerified) {
            return DocumentVerificationView(
              token: session.token,
              driverId: session.driverId,
            );
          }

          if (session.isDriverVerified && session.isDriverDocumentsVerified) {
            return TripRequestView(
              controller: TripRequestController(
                token: session.token,
                driverId: session.driverId,
                vehicleType: 'BIKE',
                driverStatus: 'ONLINE',
              ),
            );
          }

          // Driver not verified at all yet — treat as logged out
          return AuthView(controller: _controller);
        },
      ),
    );
  }
}
