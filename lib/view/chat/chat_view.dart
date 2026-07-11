import 'package:flutter/material.dart';
import 'package:swiftbike_driver/controller/chat_controller.dart';
import 'package:swiftbike_driver/core/colors/app_colors.dart';
import 'package:swiftbike_driver/model/chat_model.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key, required this.controller});

  final ChatController controller;

  static const List<String> _quickReplies = [
    "I am on my way",
    "Please share your location",
    "I have arrived",
    "Call me when ready",
  ];

  Widget _buildHeader(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 14,
            compact ? 6 : 8,
            compact ? 16 : 20,
            compact ? 14 : 16,
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(36),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bike_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Rider",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withAlpha(46)),
                ),
                child: const Text(
                  "Ride active",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildMessageBubble(BuildContext context, ChatModel message) {
    final bubbleColor = message.isMe ? AppColors.primaryLight : Colors.white;
    const textColor = AppColors.textPrimary;
    const metaColor = AppColors.textSecondary;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe)
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isMe ? 18 : 6),
                  bottomRight: Radius.circular(message.isMe ? 6 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: message.isMe
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.senderLabel,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.time),
                        style: const TextStyle(
                          color: metaColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (message.isMe && message.status != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          message.status!,
                          style: const TextStyle(
                            color: metaColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe)
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_pin_circle_rounded,
                color: AppColors.primaryDark,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 16,
          12,
          compact ? 14 : 16,
          compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final reply = _quickReplies[i];
                  return ActionChip(
                    onPressed: () => controller.sendMessage(reply),
                    label: Text(reply),
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: AppColors.background,
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 140,
                        minHeight: 48,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: controller.messageController,
                        scrollController: controller.fieldScrollController,
                        scrollPhysics: const BouncingScrollPhysics(),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: "Message rider or driver...",
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withAlpha(204),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: compact ? 14 : 16,
                            vertical: compact ? 13 : 15,
                          ),
                        ),
                        onSubmitted: (_) => controller.sendMessage(),
                        onChanged: (_) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (controller.fieldScrollController.hasClients) {
                              controller.fieldScrollController.jumpTo(
                                controller
                                    .fieldScrollController
                                    .position
                                    .maxScrollExtent,
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: controller.sending
                          ? null
                          : () => controller.sendMessage(),
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        height: 48,
                        width: 48,
                        child: Center(
                          child: controller.sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFFECE5DD),
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF6FBF8),
                              Color(0xFFEAF4FF),
                              AppColors.primaryLight,
                            ],
                            stops: [0.0, 0.55, 1.0],
                          ),
                        ),
                        child: Opacity(
                          opacity: 0.26,
                          child: CustomPaint(painter: _ChatPatternPainter()),
                        ),
                      ),
                    ),
                    ListView.builder(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                      itemCount: controller.messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildDateChip("Today");
                        }
                        final message = controller.messages[index - 1];
                        return _buildMessageBubble(context, message);
                      },
                    ),
                  ],
                ),
              ),
              _buildComposer(context),
            ],
          ),
        );
      },
    );
  }
}

class _ChatPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = AppColors.primaryLight.withAlpha(70);
    final accentPaint = Paint()..color = AppColors.primary.withAlpha(28);

    for (double y = 20; y < size.height + 40; y += 64) {
      for (double x = 18; x < size.width + 36; x += 72) {
        canvas.drawCircle(Offset(x, y), 2.6, lightPaint);
        canvas.drawCircle(Offset(x + 18, y + 18), 1.6, accentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
