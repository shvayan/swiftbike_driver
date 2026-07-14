import 'package:flutter/material.dart';

import '../model/chat_model.dart';
import '../service/trip_request_service.dart';

class ChatController extends ChangeNotifier {
  ChatController(
    this.tripId,
    this.senderId,
    this.reserverId,
    this._service, // shared, already-connected instance — do NOT create a new one
  );

  final String tripId;
  final String senderId;
  final String reserverId;
  final TripRequestService _service;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ScrollController fieldScrollController = ScrollController();

  final List<ChatModel> messages = [];
  bool sending = false;

  /// Called by whoever forwards chat data from the shared socket
  /// (TripRequestController.chatMessages.listen(this.handleIncoming)).
  void handleIncoming(Map<String, dynamic> data) {
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
    super.dispose();
    messageController.dispose();
    scrollController.dispose();
    fieldScrollController.dispose();
  }
}
