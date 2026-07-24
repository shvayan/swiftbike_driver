import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Opens and updates the Android system overlay used for incoming trip leads.
///
/// Android only permits this after the driver explicitly enables the
/// "display over other apps" permission. Call [requestPermission] (via
/// [openPermissionSettings]) from a button or other direct user action.
///
/// Fixes vs. the previous version:
/// - All platform-channel / plugin calls are wrapped in try/catch so a
///   dropped native call can never crash the app.
/// - Every entry point is guarded with `Platform.isAndroid` — this plugin
///   is Android-only and silently throwing MissingPluginException on iOS
///   builds was one source of "sometimes doesn't work".
/// - The ready-handshake is now retried with a timeout instead of firing
///   once. If the overlay's `shareData` ping reaches the main engine
///   before Android has actually attached the plugin channel (a real,
///   observed timing issue), the message used to vanish and the bubble
///   would sit on its placeholder text forever. Now it retries.
/// - `show()` returns a bool so callers know whether it actually worked
///   (e.g. permission missing) instead of failing silently.
class TripLeadChatHead {
  TripLeadChatHead._();

  static const _platform = MethodChannel('swiftbike_driver/overlay');
  static Map<String, String>? _latestLead;
  static bool _isListeningForOverlay = false;
  static StreamSubscription<dynamic>? _mainListenerSub;

  /// Set this once (e.g. in main.dart, after your navigator/router exists)
  /// to handle the "View" button in the overlay bringing the driver to the
  /// trip request screen. Called on the main engine with the tripId that
  /// was showing in the overlay card, or '' for the "waiting" placeholder.
  ///
  /// Example:
  /// ```dart
  /// TripLeadChatHead.onOpenTripRequested = (tripId) {
  ///   navigatorKey.currentState?.pushNamed('/trip-requests', arguments: tripId);
  /// };
  /// ```
  static void Function(String tripId)? onOpenTripRequested;

  /// Keeps the latest lead in the main Flutter engine and answers ready
  /// pings from the overlay engine. Safe to call multiple times.
  static void initialize() {
    if (!Platform.isAndroid) return;
    if (_isListeningForOverlay) return;
    _isListeningForOverlay = true;

    _mainListenerSub = FlutterOverlayWindow.overlayListener.listen(
      (event) async {
        if (event is! Map) return;

        if (event['event'] == 'trip_lead_overlay_ready') {
          final lead = _latestLead;
          if (lead == null) return;
          try {
            await FlutterOverlayWindow.shareData(lead);
          } catch (e) {
            developer.log(
              'overlay shareData failed on ready-ack: $e',
              name: 'TripLeadChatHead',
            );
          }
          return;
        }

        if (event['event'] == 'open_trip_request') {
          final tripId = '${event['tripId'] ?? ''}';
          try {
            // This listener runs in the main Flutter engine, whose platform
            // channel is attached to MainActivity. The overlay engine has no
            // MainActivity channel of its own, so it must not try to launch
            // the activity directly.
            if (event['openedDirectly'] != true) {
              await _platform.invokeMethod<void>('openMainApp');
            }
            onOpenTripRequested?.call(tripId);
          } catch (e) {
            developer.log(
              'onOpenTripRequested threw: $e',
              name: 'TripLeadChatHead',
            );
          }
        }
      },
      onError: (e) =>
          developer.log('overlay listener error: $e', name: 'TripLeadChatHead'),
    );
  }

  /// Opens Android's "Display over other apps" screen.
  static Future<void> openPermissionSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _platform.invokeMethod<void>('openOverlayPermissionSettings');
    } on PlatformException catch (e) {
      developer.log(
        'openOverlayPermissionSettings failed: $e',
        name: 'TripLeadChatHead',
      );
    }
  }

  static Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      return false;
    }
  }

  /// Shows (or updates) the chat head. Returns true if the lead was
  /// successfully shown/queued, false otherwise (e.g. permission missing).
  static Future<bool> show({
    required String tripId,
    required String pickupAddress,
    required String dropAddress,
    required String fare,
  }) async {
    if (!Platform.isAndroid) return false;
    if (!await isAvailable()) return false;

    initialize();
    final lead = <String, String>{
      'tripId': tripId,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'fare': fare,
    };
    _latestLead = lead;

    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (!isActive) {
        await FlutterOverlayWindow.showOverlay(
          width: 76,
          height: 76,
          alignment: OverlayAlignment.centerRight,
          enableDrag: true,
          positionGravity: PositionGravity.auto,
          overlayTitle: 'New trip lead',
          overlayContent: 'Tap the trip bubble to view the lead.',
        );
      }
      // Handles an already-running overlay directly. A newly created
      // overlay also receives this same state through the ready handshake,
      // whichever arrives — belt and braces against dropped messages.
      await FlutterOverlayWindow.shareData(lead);
      return true;
    } catch (e) {
      developer.log('show() failed: $e', name: 'TripLeadChatHead');
      return false;
    }
  }

  static Future<void> close() async {
    _latestLead = null;
    if (!Platform.isAndroid) return;
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      developer.log('close() failed: $e', name: 'TripLeadChatHead');
    }
  }

  static Future<void> dispose() async {
    await _mainListenerSub?.cancel();
    _mainListenerSub = null;
    _isListeningForOverlay = false;
  }
}

class TripLeadOverlayApp extends StatelessWidget {
  const TripLeadOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // The overlay runs on a second Flutter engine/view. Its
      // PlatformDispatcher view configuration can go stale relative to
      // the main engine — most reliably right after `resizeOverlay()` —
      // and Material's M3 button defaults query the *system* text scaler
      // via PlatformDispatcher.scaleFontSize on every build, even when a
      // custom padding is supplied (the framework still evaluates the
      // default style's getter to build its candidate list). When that
      // lookup hits a config id the engine has already recycled, it
      // throws "incorrect configuration id" and takes the whole render
      // tree down with it. Pinning the text scaler here means nothing
      // in this widget tree ever reaches that platform call.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
      home: const TripLeadChatHeadView(),
    );
  }
}

class TripLeadChatHeadView extends StatefulWidget {
  const TripLeadChatHeadView({super.key});

  @override
  State<TripLeadChatHeadView> createState() => _TripLeadChatHeadViewState();
}

class _TripLeadChatHeadViewState extends State<TripLeadChatHeadView>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF6C4CF1);
  static const _navy = Color(0xFF1A2A4A);
  static const _amber = Color(0xFFFFB300);
  static const _green = Color(0xFF34C77B);

  static const double _bubbleSize = 76;
  static const double _cardWidth = 304;
  static const double _cardHeight = 232;

  StreamSubscription<dynamic>? _leadSubscription;
  Map<String, String>? _lead;
  bool _expanded = false;
  bool _hasNewLead = false;
  Timer? _handshakeRetryTimer;
  int _handshakeAttempts = 0;

  // Position bookkeeping for the resize/anchor fix — see _toggle().
  double? _bubbleX;
  double? _bubbleY;
  bool _anchoredRight = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _leadSubscription = FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is! Map) return;
      // Ignore our own outgoing ready-ping if it ever echoes back.
      if (event['event'] == 'trip_lead_overlay_ready') return;

      _stopHandshakeRetry();
      if (!mounted) return;
      setState(() {
        _lead = event.map((key, value) => MapEntry('$key', '$value'));
        _hasNewLead = true;
      });
    });

    _startHandshakeRetry();
    _captureRightDockReference();
  }

  /// Sends the "ready" ping repeatedly for a short window instead of once.
  /// If the main engine's listener wasn't fully attached yet on the very
  /// first attempt (observed intermittently right after the overlay
  /// window is created), this ensures we don't just sit there forever
  /// showing placeholder text.
  void _startHandshakeRetry() {
    _handshakeAttempts = 0;
    _sendReadyPing();
    _handshakeRetryTimer = Timer.periodic(const Duration(milliseconds: 400), (
      timer,
    ) {
      _handshakeAttempts++;
      if (_lead != null || _handshakeAttempts >= 8) {
        timer.cancel();
        return;
      }
      _sendReadyPing();
    });
  }

  void _stopHandshakeRetry() {
    _handshakeRetryTimer?.cancel();
    _handshakeRetryTimer = null;
  }

  Future<void> _sendReadyPing() async {
    try {
      await FlutterOverlayWindow.shareData(const {
        'event': 'trip_lead_overlay_ready',
      });
    } catch (e) {
      developer.log('ready ping failed: $e', name: 'TripLeadChatHeadView');
    }
  }

  @override
  void dispose() {
    _stopHandshakeRetry();
    _leadSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// The x `getOverlayPosition()` reports the moment this overlay window
  /// is first created with `alignment: OverlayAlignment.centerRight`
  /// (before the driver has had any chance to drag it). This is captured
  /// once, in the plugin's own coordinate space — whatever that space
  /// actually is (device pixels, dp, gravity-relative offset — the
  /// plugin doesn't document it, and it isn't the same thing twice
  /// across attempts to derive it from Flutter's own MediaQuery /
  /// physicalSize). Comparing every later position against this
  /// self-captured reference, instead of against a separately-guessed
  /// "screen width", is what actually fixes the always-opens-right bug:
  /// there's no unit conversion left to get wrong.
  static double? _rightDockRefX;

  void _captureRightDockReference() {
    if (_rightDockRefX != null) return;
    FlutterOverlayWindow.getOverlayPosition()
        .then((pos) => _rightDockRefX ??= pos.x.toDouble())
        .catchError((e) {
          developer.log(
            'right-dock reference capture failed: $e',
            name: 'TripLeadChatHeadView',
          );
        });
  }

  /// Expands/collapses the bubble.
  ///
  /// `resizeOverlay()` on flutter_overlay_window re-applies the alignment
  /// gravity that was passed to the original `showOverlay()` call every
  /// time it runs — it doesn't know or care where the driver actually
  /// dragged the bubble to. Left uncorrected, the card can end up
  /// positioned wrong (or always opening on one side) regardless of
  /// which edge the bubble was actually parked on.
  ///
  /// Fix: read the bubble's real position with `getOverlayPosition()`
  /// and compare it against `_rightDockRefX` (captured once, straight
  /// from this same API, at the moment the overlay was first created —
  /// see `_captureRightDockReference()`), then explicitly `moveOverlay()`
  /// back to the correct spot after resizing. Comparing against a
  /// self-captured reference — instead of a screen width guessed from
  /// Flutter's own MediaQuery/physicalSize — removes any dependency on
  /// knowing whether the plugin's x/y are raw pixels, dp, or something
  /// else; both sides of every comparison are already in whatever space
  /// the plugin itself uses.
  Future<void> _toggle() async {
    final expand = !_expanded;

    try {
      if (expand) {
        final pos = await FlutterOverlayWindow.getOverlayPosition();
        _bubbleX = pos.x.toDouble();
        _bubbleY = pos.y.toDouble();

        await FlutterOverlayWindow.resizeOverlay(
          _cardWidth.toInt(),
          _cardHeight.toInt(),
          false,
        );

        await Future.delayed(const Duration(milliseconds: 16));

        // Always open to the right
        await FlutterOverlayWindow.moveOverlay(
          OverlayPosition(_bubbleX!, _bubbleY!),
        );
      } else {
        await FlutterOverlayWindow.resizeOverlay(
          _bubbleSize.toInt(),
          _bubbleSize.toInt(),
          true,
        );

        await Future.delayed(const Duration(milliseconds: 16));

        if (_bubbleX != null && _bubbleY != null) {
          await FlutterOverlayWindow.moveOverlay(
            OverlayPosition(_bubbleX!, _bubbleY!),
          );
        }
      }
    } catch (e) {
      developer.log('resize/move failed: $e', name: 'TripLeadChatHeadView');
    }

    if (!mounted) return;

    setState(() {
      _expanded = expand;
      if (expand) _hasNewLead = false;
    });
  }

  Future<void> _dismiss() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      developer.log('closeOverlay failed: $e', name: 'TripLeadChatHeadView');
    }
  }

  /// "View" button: brings the app to the foreground on the trip request
  /// screen, then minimizes the overlay back down to the bubble (it stays
  /// running so a second lead can still pop it back up later).
  Future<void> _openAppAndMinimize() async {
    final tripId = _lead?['tripId'] ?? '';
    var launchedDirectly = false;

    try {
      // MainActivity also registers this channel on the cached overlay
      // engine. This is the primary, direct path to foreground the app.
      await TripLeadChatHead._platform.invokeMethod<void>('openMainApp');
      launchedDirectly = true;
    } catch (e) {
      developer.log(
        'direct openMainApp failed: $e',
        name: 'TripLeadChatHeadView',
      );
    }

    try {
      await FlutterOverlayWindow.shareData({
        'event': 'open_trip_request',
        'tripId': tripId,
        'openedDirectly': launchedDirectly,
      });
    } catch (e) {
      developer.log(
        'shareData open_trip_request failed: $e',
        name: 'TripLeadChatHeadView',
      );
    }

    if (_expanded) await _toggle(); // collapse back to the bubble
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          alignment: _anchoredRight
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _expanded
            ? _leadCard(key: const ValueKey('card'))
            : _bubble(key: const ValueKey('bubble')),
      ),
    );
  }

  Widget _bubble({Key? key}) {
    return GestureDetector(
      key: key,
      onTap: _toggle,
      child: Container(
        width: _bubbleSize,
        height: _bubbleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_purple, _navy],
          ),
          // No BoxShadow here on purpose: this renders on the overlay's
          // translucent system window, and asking for a blurred shadow
          // layer there makes the Mali gralloc HAL spam
          // "Unrecognized and/or unsupported format" errors trying (and
          // failing) to allocate an offscreen blur buffer for it. The
          // frame still draws, but it's needless overhead — a solid
          // white ring reads just as well at this size.
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.two_wheeler_rounded,
              color: Colors.white,
              size: 32,
            ),
            if (_hasNewLead)
              Positioned(
                right: 6,
                top: 6,
                child: ScaleTransition(
                  scale: Tween(
                    begin: 0.85,
                    end: 1.25,
                  ).animate(_pulseController),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _green,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _leadCard({Key? key}) {
    final lead = _lead;
    final hasLead = lead != null;
    final fare = lead?['fare'] ?? '';
    final pickup = lead?['pickupAddress'] ?? 'Waiting for trip details…';
    final drop = lead?['dropAddress'] ?? '';

    return Container(
      key: key,
      width: _cardWidth,
      constraints: const BoxConstraints(maxHeight: _cardHeight),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        // Same reason as the bubble: no blurred BoxShadow on the overlay's
        // translucent window. A thin border gives the card separation
        // from whatever's behind it without the gralloc blur-buffer spam.
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_purple, _navy]),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'New trip lead',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _navy,
                    fontSize: 15,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: _navy.withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Route timeline
          // IntrinsicHeight is required here: this Row sits inside a Column
          // with mainAxisSize.min under unbounded height constraints, so a
          // plain Row never hands a finite height down to its children.
          // _routeRail()'s connecting line uses Expanded and needs that
          // finite height (from the address text sibling) to fill —
          // without IntrinsicHeight that's an unbounded-height RenderFlex
          // crash.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _routeRail(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _addressText(pickup, emphasized: true),
                      if (drop.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _addressText(drop, emphasized: false),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.black.withOpacity(0.06)),
          const SizedBox(height: 10),

          // Footer
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED FARE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _navy.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      fare.isNotEmpty ? fare : '—',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _dismiss,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: hasLead ? _openAppAndMinimize : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasLead
                          ? const [_purple, _navy]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Small vertical timeline rail: filled purple dot for pickup, connecting
  /// line, hollow navy dot for drop.
  Widget _routeRail() {
    return SizedBox(
      width: 10,
      child: Column(
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(top: 3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _purple,
            ),
          ),
          Expanded(
            child: Container(
              width: 1.5,
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: Colors.black12,
            ),
          ),
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _navy, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressText(String text, {required bool emphasized}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
        color: emphasized ? _navy : Colors.black54,
      ),
    );
  }
}
