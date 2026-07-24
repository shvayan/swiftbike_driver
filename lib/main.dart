import 'package:flutter/material.dart';

import 'controller/auth_controller.dart';
import 'controller/trip_request_controller.dart';
import 'service/auth_session_service.dart';
import 'view/trip_request_view.dart';
import 'view/auth_view.dart';
import 'view/document_verification_view.dart';
import 'view/overlay/trip_lead_chat_head.dart';

/// Lets code outside the widget tree (like the overlay's "View" button
/// callback) drive navigation — push, pop, popUntil — without needing a
/// BuildContext of its own.
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TripLeadChatHead.initialize();

  // Overlay "View" button -> app is brought to the foreground natively,
  // then this pops back to the root route (TripRequestView, once logged
  // in) in case a ChatView or anything else was pushed on top. The
  // TripRequestView itself already streams the live request list, so it
  // will already be showing the same trip the overlay was displaying.
  TripLeadChatHead.onOpenTripRequested = (tripId) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  };

  runApp(const MyApp());
}

/// Separate Flutter entry point used by Android when the app is in the
/// background and the system renders the chat-head window.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TripLeadOverlayApp());
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
      navigatorKey: navigatorKey,
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
