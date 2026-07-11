class ChatModel {
  final String text;
  final bool isMe;
  final DateTime time;
  final String? status;
  final String senderLabel;

  const ChatModel({
    required this.text,
    required this.isMe,
    required this.time,
    required this.senderLabel,
    this.status,
  });
}
