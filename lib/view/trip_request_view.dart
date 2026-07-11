import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swiftbike_driver/core/colors/app_colors.dart';
import 'package:swiftbike_driver/core/helper/amount_helper.dart';
import 'package:swiftbike_driver/core/helper/ringtone_helper.dart';

import '../controller/trip_request_controller.dart';

// ---------------------------------------------------------------------------
// Derived tints/shades not present as named colors in AppColors. Built from
// the real brand values (AppColors.primaryDark, AppColors.error) so this
// stays in sync if the brand color ever changes. Kept private to this file —
// promote to AppColors if you want these reused elsewhere.
// ---------------------------------------------------------------------------
class _Palette {
  _Palette._();

  static const Color primary = AppColors.primaryDark; // #6C4CF1
  static final Color primaryDeep = Color.lerp(primary, Colors.black, 0.25)!;
  static final Color primarySoft = Color.lerp(primary, Colors.white, 0.90)!;
  static final Color primarySofter = Color.lerp(primary, Colors.white, 0.95)!;

  static const Color danger = AppColors.error;
  static final Color dangerSoft = Color.lerp(danger, Colors.white, 0.90)!;
}

class TripRequestView extends StatefulWidget {
  const TripRequestView({super.key, required this.controller});

  final TripRequestController controller;

  @override
  State<TripRequestView> createState() => _TripRequestViewState();
}

class _TripRequestViewState extends State<TripRequestView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 20,
        title: Text(
          'Driver Lead',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final controller = widget.controller;
          // Real list of pending requests from the controller — each item
          // is independent, with its own tripId, fare, and countdown.
          final requests = controller.requests;

          final statusText = controller.isConnecting
              ? 'Connecting to live trip feed...'
              : requests.isEmpty
              ? 'Waiting for a new request...'
              : requests.length == 1
              ? 'New request available'
              : '${requests.length} new requests available';

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _StatusHeader(
                    statusText: statusText,
                    locationError: controller.locationError,
                    message: controller.message,
                    tripCount: requests.length,
                  ),
                ),
                Expanded(
                  child: requests.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: _EmptyRequestPanel(statusText: statusText),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: requests.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final payload = requests[index];
                            final tripDetails = payload.tripDetails;
                            final pickupDistance =
                                payload.driverToRiderDistance?.distanceKm;

                            return _TripCard(
                              key: ValueKey(tripDetails.tripId),
                              tripDetails: tripDetails,
                              pickupDistance: pickupDistance,
                              isSending: controller.isSending,
                              onDeny: () =>
                                  controller.denyTrip(tripDetails.tripId),
                              onAccept: () =>
                                  controller.acceptTrip(tripDetails.tripId),
                              onExpired: () =>
                                  controller.dismissTrip(tripDetails.tripId),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A single trip request card with a 15-segment countdown.
///
/// The countdown itself is a local UI timer — it does not talk to the
/// controller directly except to call [onExpired] once it runs out, so
/// the controller (the single source of truth for the request list) can
/// remove this trip.
class _TripCard extends StatefulWidget {
  const _TripCard({
    super.key,
    required this.tripDetails,
    required this.pickupDistance,
    required this.isSending,
    required this.onDeny,
    required this.onAccept,
    required this.onExpired,
  });

  final dynamic tripDetails;
  final dynamic pickupDistance;
  final bool isSending;
  final VoidCallback onDeny;
  final VoidCallback onAccept;
  final VoidCallback onExpired;

  static const int totalSegments = 15;

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  late int _segmentsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _segmentsLeft = _TripCard.totalSegments;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    RingtoneHelper.play();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segmentsLeft <= 1) {
        RingtoneHelper.stop();
        timer.cancel();
        setState(() => _segmentsLeft = 0);
        // Notify the parent after this frame so it can remove the card.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onExpired();
        });
        return;
      }
      setState(() => _segmentsLeft--);
    });
  }

  @override
  void didUpdateWidget(covariant _TripCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset the countdown if this card now represents a different trip.
    if (oldWidget.tripDetails.tripId != widget.tripDetails.tripId) {
      setState(() => _segmentsLeft = _TripCard.totalSegments);
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripDetails = widget.tripDetails;
    final pickupDistance = widget.pickupDistance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _Palette.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SegmentedCountdown(
                  totalSegments: _TripCard.totalSegments,
                  segmentsLeft: _segmentsLeft,
                ),
              ),
              const SizedBox(width: 12),
              _CountdownBadge(segmentsLeft: _segmentsLeft),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _Palette.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.two_wheeler_rounded, color: _Palette.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Request',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'New request available',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EyebrowLabel('FARE'),
                    const SizedBox(height: 4),
                    Text(
                      AmountHelper.format(
                        tripDetails.tripCreatePriceRequest.totalFare,
                      ),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 34, color: _Palette.primarySoft),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EyebrowLabel('YOU EARN'),
                    const SizedBox(height: 4),
                    Text(
                      AmountHelper.format(
                        tripDetails.tripCreatePriceRequest.driverEarning,
                      ),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: _Palette.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  icon: Icons.schedule_rounded,
                  label: 'ETA',
                  value: tripDetails.routeRequest.eta,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricChip(
                  icon: Icons.route_rounded,
                  label: 'Distance',
                  value: '${tripDetails.routeRequest.distanceKm} km',
                ),
              ),
              if (pickupDistance != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricChip(
                    icon: Icons.near_me_rounded,
                    label: 'Pickup',
                    value: '$pickupDistance km',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _RoutePanel(
            pickupAddress: tripDetails.pickupAddress,
            dropAddress: tripDetails.dropAddress,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: widget.isSending ? null : widget.onDeny,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _Palette.danger,
                      side: BorderSide(color: _Palette.dangerSoft, width: 1.5),
                      backgroundColor: _Palette.dangerSoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Deny',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [_Palette.primary, _Palette.primaryDeep],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _Palette.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: widget.isSending ? null : widget.onAccept,
                        child: const Center(
                          child: Text(
                            'Accept trip',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _Palette.primarySofter,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: _Palette.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact numeric badge showing seconds remaining, ring-colored by urgency.
class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.segmentsLeft});

  final int segmentsLeft;

  @override
  Widget build(BuildContext context) {
    final urgent = segmentsLeft <= 5;
    final color = urgent ? _Palette.danger : _Palette.primary;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Text(
        '$segmentsLeft',
        style: TextStyle(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _SegmentedCountdown extends StatelessWidget {
  const _SegmentedCountdown({
    required this.totalSegments,
    required this.segmentsLeft,
  });

  final int totalSegments;
  final int segmentsLeft;

  @override
  Widget build(BuildContext context) {
    final urgent = segmentsLeft <= 5;
    final activeColor = urgent ? _Palette.danger : _Palette.primary;

    return Row(
      children: [
        for (var i = 0; i < totalSegments; i++) ...[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < segmentsLeft ? activeColor : _Palette.primarySoft,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (i != totalSegments - 1) const SizedBox(width: 3),
        ],
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.statusText,
    required this.locationError,
    required this.message,
    required this.tripCount,
  });

  final String statusText;
  final String? locationError;
  final String? message;
  final int tripCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [_Palette.primary, _Palette.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.primary.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  tripCount == 0
                      ? Icons.hourglass_empty_rounded
                      : Icons.bolt_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Requests',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (locationError != null) ...[
            const SizedBox(height: 14),
            _NoticeBanner(
              icon: Icons.location_off_rounded,
              message: locationError!,
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: 12),
            _NoticeBanner(icon: Icons.info_outline_rounded, message: message!),
          ],
        ],
      ),
    );
  }
}

class _RoutePanel extends StatelessWidget {
  const _RoutePanel({required this.pickupAddress, required this.dropAddress});

  final String pickupAddress;
  final String dropAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _Palette.primarySofter,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _RoutePoint(
            label: 'Pickup',
            address: pickupAddress,
            color: _Palette.primary,
            filled: true,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 24,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: _Palette.primarySoft,
              ),
            ),
          ),
          _RoutePoint(
            label: 'Dropoff',
            address: dropAddress,
            color: _Palette.danger,
            filled: false,
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.label,
    required this.address,
    required this.color,
    required this.filled,
  });

  final String label;
  final String address;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? color : Colors.white,
              border: Border.all(color: color, width: 2),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyRequestPanel extends StatelessWidget {
  const _EmptyRequestPanel({required this.statusText});

  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _Palette.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: _Palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.two_wheeler_rounded,
              size: 40,
              color: _Palette.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your next trip request will appear here in real time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
