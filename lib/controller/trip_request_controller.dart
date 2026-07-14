import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swiftbike_driver/core/helper/ringtone_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../model/trip_request_model.dart';
import '../service/trip_request_service.dart';

class TripRequestController extends ChangeNotifier {
  TripRequestController({
    TripRequestService? service,
    String? token,
    String? driverId,
    String vehicleType = 'BIKE',
    String driverStatus = 'ONLINE',
  }) : service = service ?? TripRequestService(),
       _token = token,
       _driverId = driverId,
       _vehicleType = vehicleType,
       _driverStatus = driverStatus {
    _connect();
    _initCurrentLocation();
  }

  final TripRequestService service;
  final String? _token;
  final String? _driverId;
  final String _vehicleType;
  final String _driverStatus;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _locationUpdateTimer;

  bool _isConnecting = true;
  bool _isSending = false;
  String? _message;

  // All currently active trip requests, most recent last. A driver can
  // have more than one pending request at once, so this replaces the old
  // single `_currentRequest` field.
  final List<TripRequestPayload> _requests = [];

  Position? _currentPosition;
  String? _locationError;

  bool get isConnecting => _isConnecting;
  bool get isSending => _isSending;
  String? get message => _message;

  /// All currently pending trip requests.
  List<TripRequestPayload> get requests => List.unmodifiable(_requests);
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatMessages => _chatController.stream;

  /// Kept for any callers still expecting a single request (returns the
  /// most recent one, or null if none are pending).
  TripRequestPayload? get currentRequest =>
      _requests.isEmpty ? null : _requests.last;

  Position? get currentPosition => _currentPosition;
  String? get locationError => _locationError;
  final Map<String, DateTime> _expiryByTripId = {};
  DateTime expiresAtFor(String tripId) =>
      _expiryByTripId[tripId] ?? DateTime.now();

  void _upsertRequest(TripRequestPayload request) {
    final tripId = request.tripDetails.tripId;
    final idx = _requests.indexWhere((r) => r.tripDetails.tripId == tripId);

    if (idx >= 0) {
      _requests[idx] = request; // update existing, keep its original expiry
    } else {
      _requests.insert(0, request); // newest first
      _expiryByTripId[tripId] = DateTime.now().add(const Duration(seconds: 15));
    }
    notifyListeners();
  }

  void _connect() {
    _channel = service.connect(token: _token);
    _subscription = _channel!.stream.listen(
      (event) {
        print('Received socket message: $event');
        try {
          final Map<String, dynamic> data = jsonDecode(event);
          final type = data['type']?.toString();

          switch (type) {
            case 'LOCATION_UPDATE':
              // ignore location updates for now
              break;

            case 'CHAT':
              _chatController.add(data);
              // Not this controller's job — forward to chat if this socket is shared,
              // otherwise just ignore here.
              break;

            default:
              // Trip requests apparently don't carry an explicit 'type', so treat
              // anything else as a trip request IF it actually has tripDetails.
              if (data['tripDetails'] != null) {
                final request = service.parseTripRequest(event);
                _upsertRequest(request);
                _message = 'New trip request received';
              }
          }
        } catch (error) {
          _message = 'Invalid socket message: $error';
        }
        _isConnecting = false;
        notifyListeners();
      },
      onError: (error) {
        _message = 'Socket error: $error';
        _isConnecting = false;
        notifyListeners();
      },
      onDone: () {
        _message = 'Socket closed';
        _isConnecting = false;
        notifyListeners();
      },
    );
    debugPrint('Subscription: $_subscription');
    _isConnecting = false;
    _message = 'Waiting for a new trip request...';
    notifyListeners();
  }

  /// Adds a new request, or replaces the existing one with the same
  /// tripId if a duplicate/updated message arrives for it.

  Future<void> _initCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _locationError = 'Location services are disabled';
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationError = 'Location permission denied';
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _locationError = null;
      _startAutoLocationUpdates();
      notifyListeners();
    } catch (error) {
      _locationError = 'Failed to get current location: $error';
      notifyListeners();
    }
  }

  /// Accepts the trip with the given [tripId].
  Future<void> acceptTrip(String tripId) async {
    RingtoneHelper.stop();
    await _sendTripAction('TRIP_ACCEPT', tripId);
    _requests.removeWhere((r) => r.tripDetails.tripId == tripId);
    _message = 'Trip accepted';
    notifyListeners();
  }

  /// Denies the trip with the given [tripId].
  Future<void> denyTrip(String tripId) async {
    RingtoneHelper.stop();
    await _sendTripAction('TRIP_REJECT', tripId);
    _requests.removeWhere((r) => r.tripDetails.tripId == tripId);
    _message = 'Trip denied';
    notifyListeners();
  }

  /// Removes a trip request from view without notifying the server —
  /// used when a request's countdown expires locally.
  void dismissTrip(String tripId) {
    _requests.removeWhere((r) => r.tripDetails.tripId == tripId);
    _expiryByTripId.remove(tripId); // clean up so the map doesn't grow forever
    notifyListeners();
  }

  Future<void> sendLocationUpdate({
    required String driverId,
    required String driverStatus,
    required String vehicleType,
    required double currentLatitude,
    required double currentLongitude,
    required String timestamp,
  }) async {
    if (_channel == null) {
      return;
    }

    _isSending = true;
    notifyListeners();

    try {
      service.sendMessage(
        service.buildLocationUpdate(
          driverId: driverId,
          driverStatus: driverStatus,
          vehicleType: vehicleType,
          currentLatitude: currentLatitude,
          currentLongitude: currentLongitude,
          timestamp: timestamp,
        ),
      );
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> updateCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _locationError = 'Location services are disabled';
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationError = 'Location permission denied';
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _locationError = null;
      _startAutoLocationUpdates();
      await _sendCurrentPosition(_currentPosition!);
      notifyListeners();
    } catch (error) {
      _locationError = 'Failed to update current location: $error';
      notifyListeners();
    }
  }

  void _startAutoLocationUpdates() {
    if (_locationUpdateTimer != null) {
      return;
    }

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      await updateCurrentLocation();
    });
  }

  Future<void> _sendCurrentPosition(Position position) async {
    final driverId = _driverId;
    if (driverId == null || driverId.isEmpty || _channel == null) {
      return;
    }

    await sendLocationUpdate(
      driverId: driverId,
      driverStatus: _driverStatus,
      vehicleType: _vehicleType,
      currentLatitude: position.latitude,
      currentLongitude: position.longitude,
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> _sendTripAction(String type, String tripId) async {
    if (_channel == null) {
      return;
    }

    _isSending = true;
    notifyListeners();

    try {
      service.sendMessage(service.buildTripAction(type: type, tripId: tripId));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _locationUpdateTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
