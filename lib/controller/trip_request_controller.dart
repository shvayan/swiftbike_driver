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
    if (isOnline) _connect();
    _startSocketHealthChecks();
    _initCurrentLocation();
  }

  final TripRequestService service;
  final String? _token;
  final String? _driverId;
  final String _vehicleType;
  String _driverStatus;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _locationUpdateTimer;
  Timer? _socketHealthTimer;

  bool _isConnecting = false;
  bool _isSending = false;
  bool _isSocketOpen = false;
  bool _isChangingAvailability = false;
  bool _isDisposed = false;
  String? _message;

  // All currently active trip requests, most recent last. A driver can
  // have more than one pending request at once, so this replaces the old
  // single `_currentRequest` field.
  final List<TripRequestPayload> _requests = [];

  Position? _currentPosition;
  String? _locationError;

  bool get isConnecting => _isConnecting;
  bool get isSending => _isSending;
  bool get isOnline => _driverStatus == 'ONLINE';
  bool get isSocketConnected => _isSocketOpen;
  bool get isChangingAvailability => _isChangingAvailability;
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
    if (_isDisposed || !isOnline || _isConnecting || _isSocketOpen) return;

    _isConnecting = true;
    _message = 'Connecting to live trip feed...';
    notifyListeners();

    try {
      final channel = service.connect(token: _token);
      _channel = channel;
      _isSocketOpen = true;
      _subscription = channel.stream.listen(
        (event) {
          if (!identical(_channel, channel)) return;
          print('Received socket message: $event');
          try {
            final Map<String, dynamic> data = jsonDecode(event);
            print('Parsed socket message: $data');
            final type = data['type']?.toString();

            // The backend sends trip action failures without a `type`, for
            // example:
            // {tripId: "...", message: "Trip already accepted"}
            // {tripId: "...", message: "Trip is Expired"}
            // Handle these before attempting to parse the payload as a new trip
            // request. Otherwise the stale card stays visible to this driver.
            if (!_handleTripUnavailableResponse(data)) {
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
            }
          } catch (error) {
            _message = 'Invalid socket message: $error';
          }
          _isConnecting = false;
          _isSocketOpen = true;
          notifyListeners();
        },
        onError: (error) {
          _handleSocketInterrupted(channel, 'Connection lost. Reconnecting...');
        },
        onDone: () {
          _handleSocketInterrupted(
            channel,
            'Connection closed. Reconnecting...',
          );
        },
      );
      debugPrint('Subscription: $_subscription');
      _isConnecting = false;
      _message = 'Waiting for a new trip request...';
      notifyListeners();
    } catch (error) {
      _isConnecting = false;
      _isSocketOpen = false;
      _message = 'Unable to connect. Retrying...';
      notifyListeners();
    }
  }

  void _handleSocketInterrupted(WebSocketChannel channel, String message) {
    if (!identical(_channel, channel)) return;

    service.invalidateChannel(channel);
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    _isSocketOpen = false;
    _isConnecting = false;
    if (!_isDisposed && isOnline) {
      _message = message;
      notifyListeners();
    }
  }

  void _startSocketHealthChecks() {
    _socketHealthTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isDisposed && isOnline && !_isSocketOpen && !_isConnecting) {
        _connect();
      }
    });
  }

  /// Changes whether this driver can receive trip requests. Going offline
  /// closes the live socket and deliberately pauses automatic reconnection.
  Future<void> setOnline(bool online) async {
    if (_isChangingAvailability || online == isOnline) return;

    _isChangingAvailability = true;
    notifyListeners();
    try {
      _driverStatus = online ? 'ONLINE' : 'OFFLINE';

      if (online) {
        _connect();
        await updateCurrentLocation();
      } else {
        // Send one final availability update before closing the channel.
        if (_currentPosition != null && _isSocketOpen) {
          try {
            await _sendCurrentPosition(_currentPosition!);
          } catch (_) {
            // The socket may have dropped at the same time the driver went
            // offline. Closing it below remains the important action.
          }
        }
        _locationUpdateTimer?.cancel();
        _locationUpdateTimer = null;
        _requests.clear();
        _expiryByTripId.clear();
        RingtoneHelper.stop();
        _isSocketOpen = false;
        _isConnecting = false;
        _message = 'You are offline. Go online to receive trip requests.';
        await _subscription?.cancel();
        _subscription = null;
        _channel = null;
        await service.disconnect();
      }
    } finally {
      _isChangingAvailability = false;
      if (!_isDisposed) notifyListeners();
    }
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

  /// Removes a request when the server says another driver accepted it or
  /// its offer window has expired. Returns true when [data] was one of those
  /// terminal trip responses.
  bool _handleTripUnavailableResponse(Map<String, dynamic> data) {
    final tripId = data['tripId']?.toString();
    final response = data['message']?.toString().trim().toLowerCase();

    if (tripId == null || tripId.isEmpty || response == null) {
      return false;
    }

    String? driverMessage;
    if (response == 'trip already accepted') {
      driverMessage = 'This trip was accepted by another driver.';
    } else if (response == 'trip is expired' || response == 'trip expired') {
      driverMessage = 'This trip request has expired.';
    }

    if (driverMessage == null) {
      return false;
    }

    _requests.removeWhere((r) => r.tripDetails.tripId == tripId);
    _expiryByTripId.remove(tripId);
    _message = driverMessage;
    if (_requests.isEmpty) {
      RingtoneHelper.stop();
    }
    notifyListeners();
    return true;
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
    if (!isOnline) return;
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
    if (!isOnline || _locationUpdateTimer != null) {
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
    if (driverId == null || driverId.isEmpty || !_isSocketOpen) {
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
    if (!_isSocketOpen) {
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
    _isDisposed = true;
    _subscription?.cancel();
    _locationUpdateTimer?.cancel();
    _socketHealthTimer?.cancel();
    service.disconnect();
    super.dispose();
  }
}
