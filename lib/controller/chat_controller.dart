import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:swiftbike_driver/model/chat_model.dart';
import 'package:swiftbike_driver/service/trip_request_service.dart';

// chat_controller.dart
class ChatController extends ChangeNotifier {
  ChatController(this.tripId, this.senderId, this.reserverId) {
    _connect();
  }

  final String tripId;
  final String senderId;
  final String reserverId;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ScrollController fieldScrollController = ScrollController();

  final List<ChatModel> messages = [];
  bool sending = false;
  bool socketConnected = false;

  StreamSubscription? _sub;
  final TripRequestService _service = TripRequestService();

  Future<void> _connect() async {
    final channel = _service.connect(); // pass token if needed
    _sub = channel.stream.listen(
      _onSocketData,
      onError: (e) {
        socketConnected = false;
        notifyListeners();
      },
    );
    socketConnected = true;
    notifyListeners();
  }

  void _onSocketData(dynamic raw) {
    Map<String, dynamic> data;
    try {
      data = _service.parseChatOrDecode(raw);
    } catch (e) {
      return; // malformed frame, ignore
    }

    if (data['type'] != 'CHAT')
      return; // not a chat message, ignore (e.g. LOCATION_UPDATE, trip status)

    final text = data['message']?.toString() ?? '';
    final incomingSenderId = data['senderId']?.toString();
    if (text.isEmpty || incomingSenderId == senderId) return;

    messages.add(
      ChatModel(
        text: text,
        isMe: false,
        time: DateTime.now(),
        senderLabel: "Rider",
      ),
    );
    notifyListeners();
    scrollToBottom();
  }

  Future<void> sendMessage([String? preset]) async {
    final text = (preset ?? messageController.text).trim();
    if (text.isEmpty || sending) return;

    sending = true;
    messages.add(
      ChatModel(
        text: text,
        isMe: true,
        time: DateTime.now(),
        senderLabel: "Driver",
        status: "Sending",
      ),
    );
    messageController.clear();
    notifyListeners();
    scrollToBottom();

    try {
      _service.sendMessage({
        'type': 'CHAT',
        'message': text,
        'senderId': senderId,
        'recipientId': reserverId,
        'tripId': tripId,
      });
      messages
        ..removeLast()
        ..add(
          ChatModel(
            text: text,
            isMe: true,
            time: DateTime.now(),
            senderLabel: "Driver",
            status: "Sent",
          ),
        );
    } catch (e) {
      messages
        ..removeLast()
        ..add(
          ChatModel(
            text: text,
            isMe: true,
            time: DateTime.now(),
            senderLabel: "Driver",
            status: "Failed",
          ),
        );
    } finally {
      sending = false;
      notifyListeners();
      scrollToBottom();
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    messageController.dispose();
    scrollController.dispose();
    fieldScrollController.dispose();
    super.dispose();
  }
}
