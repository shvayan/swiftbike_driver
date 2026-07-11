import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../model/trip_request_model.dart';

class TripRequestService {
  TripRequestService({WebSocketChannel? channel, String? socketUrl})
    : _channel = channel,
      _socketUrlOverride = socketUrl;

  WebSocketChannel? _channel;
  final String? _socketUrlOverride;

  static const String socketUrl = String.fromEnvironment(
    'TRIP_SOCKET_URL',
    defaultValue: 'ws://13.140.142.12:8081/socket/driver/tracking',
  );

  WebSocketChannel connect({String? token}) {
    if (_channel != null) {
      return _channel!;
    }

    final uri = _buildUri(token: token);
    _channel = WebSocketChannel.connect(uri);
    return _channel!;
  }

  TripRequestPayload parseTripRequest(dynamic message) {
    return TripRequestPayload.fromJson(_decode(message));
  }

  Map<String, dynamic> buildLocationUpdate({
    required String driverId,
    required String driverStatus,
    required String vehicleType,
    required double currentLatitude,
    required double currentLongitude,
    required String timestamp,
  }) {
    return <String, dynamic>{
      'type': 'LOCATION_UPDATE',
      'driverId': driverId,
      'driverStatus': driverStatus,
      'vehicleType': vehicleType,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'timestamp': timestamp,
    };
  }

  Map<String, dynamic> buildTripAction({
    required String type,
    required String tripId,
  }) {
    return <String, dynamic>{'type': type, 'tripId': tripId};
  }

  void sendMessage(dynamic payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  Uri _buildUri({String? token}) {
    final rawUrl = _socketUrlOverride ?? socketUrl;
    final parsed = Uri.parse(rawUrl);

    if (token == null || token.isEmpty) {
      return parsed;
    }

    final hasTokenQuery = parsed.queryParameters.containsKey('token');
    if (hasTokenQuery) {
      return parsed;
    }

    return parsed.replace(
      queryParameters: <String, String>{
        ...parsed.queryParameters,
        'token': token,
      },
    );
  }

  Map<String, dynamic> parseChatOrDecode(dynamic message) {
    return _decode(message);
  }

  Map<String, dynamic> _decode(dynamic message) {
    if (message is String) {
      return Map<String, dynamic>.from(jsonDecode(message) as Map);
    }

    if (message is Map<String, dynamic>) {
      return message;
    }

    throw FormatException('Unsupported trip request payload');
  }
}
