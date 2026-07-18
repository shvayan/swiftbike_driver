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

  bool get isConnected => _channel != null;

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

  Map<String, dynamic> parseChatOrDecode(dynamic message) {
    return _decode(message);
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
    if (_channel == null) {
      throw StateError('Socket not connected — cannot send message');
    }
    print('Sending over shared socket: $payload');
    _channel!.sink.add(jsonEncode(payload));
  }

  Future<void> disconnect() async {
    // Clear the reference before awaiting close. A close callback can trigger
    // a reconnect, which must never receive this stale channel from connect().
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
  }

  /// Drops a channel that has already failed or been closed by the server.
  /// The identity check prevents an old socket callback from clearing a newer
  /// connection that has since been established.
  void invalidateChannel(WebSocketChannel channel) {
    if (identical(_channel, channel)) {
      _channel = null;
    }
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

  Map<String, dynamic> _decode(dynamic message) {
    if (message is String) {
      return Map<String, dynamic>.from(jsonDecode(message) as Map);
    }
    if (message is Map<String, dynamic>) {
      return message;
    }
    throw FormatException('Unsupported socket payload');
  }
}
