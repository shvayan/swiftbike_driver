class TripCreatePriceRequest {
  TripCreatePriceRequest({
    required this.commissionFare,
    required this.tax,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeMultiplier,
    required this.totalFare,
    required this.driverEarning,
    required this.driverPlatformFee,
    required this.userPlatformFee,
    required this.taxAmount,
    required this.discountAmount,
  });

  final double commissionFare;
  final double tax;
  final double distanceFare;
  final double timeFare;
  final double surgeMultiplier;
  final double totalFare;
  final double driverEarning;
  final double driverPlatformFee;
  final double userPlatformFee;
  final double taxAmount;
  final double discountAmount;

  factory TripCreatePriceRequest.fromJson(Map<String, dynamic> json) {
    double readDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

    return TripCreatePriceRequest(
      commissionFare: readDouble(json['commissionFare']),
      tax: readDouble(json['tax']),
      distanceFare: readDouble(json['distanceFare']),
      timeFare: readDouble(json['timeFare']),
      surgeMultiplier: readDouble(json['surgeMultiplier']),
      totalFare: readDouble(json['totalFare']),
      driverEarning: readDouble(json['driverEarning']),
      driverPlatformFee: readDouble(json['driverPlatformFee']),
      userPlatformFee: readDouble(json['userPlatformFee']),
      taxAmount: readDouble(json['taxAmount']),
      discountAmount: readDouble(json['discountAmount']),
    );
  }
}

class RouteRequest {
  RouteRequest({
    required this.distanceKm,
    required this.durationSeconds,
    required this.durationMinutes,
    required this.eta,
    required this.polyline,
  });

  final double distanceKm;
  final int durationSeconds;
  final int durationMinutes;
  final String eta;
  final String polyline;

  factory RouteRequest.fromJson(Map<String, dynamic> json) {
    double readDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;
    int readInt(dynamic value) => (value as num?)?.toInt() ?? 0;

    return RouteRequest(
      distanceKm: readDouble(json['distanceKm']),
      durationSeconds: readInt(json['durationSeconds']),
      durationMinutes: readInt(json['durationMinutes']),
      eta: (json['eta'] ?? '').toString(),
      polyline: (json['polyline'] ?? '').toString(),
    );
  }
}

class TripDetails {
  TripDetails({
    required this.tripId,
    required this.riderId,
    required this.driverId,
    required this.tripStatus,
    required this.vehiclesType,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.startOtp,
    required this.requestedAt,
    required this.tripCreatePriceRequest,
    required this.routeRequest,
    this.paymentStatus,
    this.paymentMethod,
    this.currentLat,
    this.currentLng,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.cancelledBy,
  });

  final String tripId;
  final String riderId;
  final String? driverId;
  final String tripStatus;
  final String vehiclesType;
  final String pickupAddress;
  final String dropAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final int startOtp;
  final int requestedAt;
  final int? acceptedAt;
  final int? arrivedAt;
  final int? startedAt;
  final int? completedAt;
  final int? cancelledAt;
  final String? cancelReason;
  final String? cancelledBy;
  final String? paymentStatus;
  final String? paymentMethod;
  final double? currentLat;
  final double? currentLng;
  final TripCreatePriceRequest tripCreatePriceRequest;
  final RouteRequest routeRequest;

  factory TripDetails.fromJson(Map<String, dynamic> json) {
    double readDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;
    int readInt(dynamic value) => (value as num?)?.toInt() ?? 0;

    return TripDetails(
      tripId: (json['tripId'] ?? '').toString(),
      riderId: (json['riderId'] ?? '').toString(),
      driverId: json['driverId']?.toString(),
      tripStatus: (json['tripStatus'] ?? '').toString(),
      vehiclesType: (json['vehiclesType'] ?? '').toString(),
      pickupAddress: (json['pickupAddress'] ?? '').toString(),
      dropAddress: (json['dropAddress'] ?? '').toString(),
      pickupLat: readDouble(json['pickupLat']),
      pickupLng: readDouble(json['pickupLng']),
      dropLat: readDouble(json['dropLat']),
      dropLng: readDouble(json['dropLng']),
      startOtp: readInt(json['startOtp']),
      requestedAt: readInt(json['requestedAt']),
      acceptedAt: json['acceptedAt'] == null
          ? null
          : readInt(json['acceptedAt']),
      arrivedAt: json['arrivedAt'] == null ? null : readInt(json['arrivedAt']),
      startedAt: json['startedAt'] == null ? null : readInt(json['startedAt']),
      completedAt: json['completedAt'] == null
          ? null
          : readInt(json['completedAt']),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : readInt(json['cancelledAt']),
      cancelReason: json['cancelReason']?.toString(),
      cancelledBy: json['cancelledBy']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      currentLat: json['currentLat'] == null
          ? null
          : readDouble(json['currentLat']),
      currentLng: json['currentLng'] == null
          ? null
          : readDouble(json['currentLng']),
      tripCreatePriceRequest: TripCreatePriceRequest.fromJson(
        Map<String, dynamic>.from(
          json['tripCreatePriceRequest'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      routeRequest: RouteRequest.fromJson(
        Map<String, dynamic>.from(
          json['routeRequest'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}

class TripRequestPayload {
  TripRequestPayload({
    required this.tripDetails,
    required this.driverId,
    required this.riderId,
    required this.tripId,
    this.driverToRiderDistance,
    this.raw,
  });

  final TripDetails tripDetails;
  final String driverId;
  final String riderId;
  final String tripId;
  final RouteRequest? driverToRiderDistance;
  final Map<String, dynamic>? raw;

  factory TripRequestPayload.fromJson(Map<String, dynamic> json) {
    final tripDetailsJson = Map<String, dynamic>.from(
      json['tripDetails'] as Map? ?? const {},
    );

    return TripRequestPayload(
      tripDetails: TripDetails.fromJson(tripDetailsJson),
      driverId: (json['driverId'] ?? '').toString(),
      riderId: (json['riderId'] ?? '').toString(),
      tripId: (json['tripId'] ?? '').toString(),
      driverToRiderDistance: json['driverToRiderDistance'] == null
          ? null
          : RouteRequest.fromJson(
              Map<String, dynamic>.from(json['driverToRiderDistance'] as Map),
            ),
      raw: json,
    );
  }
}
