import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controller/document_controller.dart';
import '../model/document_model.dart';

const _kPurple = Color(0xFF6C5CE7);
const _kPurpleDark = Color(0xFF5A4BD1);
const _kAmber = Color(0xFFFBC531);
const _kTextDark = Color(0xFF2D2D3A);
const _kTextMuted = Color(0xFF9B9BAB);
const _kGreen = Color(0xFF1FAE5C);
const _kRed = Color(0xFFE5544D);

class DocumentVerificationView extends StatefulWidget {
  const DocumentVerificationView({
    super.key,
    required this.token,
    required this.driverId,
  });

  final String? token;
  final String? driverId;

  @override
  State<DocumentVerificationView> createState() =>
      _DocumentVerificationViewState();
}

class _DocumentVerificationViewState extends State<DocumentVerificationView> {
  late final DocumentController _controller;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = DocumentController(
      token: widget.token,
      driverId: widget.driverId,
    );
    _controller.fetchStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(DocumentType type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _kPurple),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: _kPurple,
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    await _controller.uploadDocument(type, File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: _kPurple,
                expandedHeight: 150,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: const Text(
                    'Document Verification',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_kPurple, _kPurpleDark],
                      ),
                    ),
                  ),
                ),
              ),
              if (_controller.isLoadingList)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _StatusSummary(controller: _controller),
                      const SizedBox(height: 20),
                      ...DocumentType.values.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _DocumentCard(
                            item: _controller.documents[type]!,
                            isUploading: _controller.uploadingType == type,
                            onTap: () => _pickAndUpload(type),
                          ),
                        ),
                      ),
                      if (_controller.message != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _controller.message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: _kRed),
                        ),
                      ],
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.controller});

  final DocumentController controller;

  @override
  Widget build(BuildContext context) {
    final verifiedCount = controller.documents.values
        .where((d) => d.status == DocumentStatus.verified)
        .length;
    final total = controller.documents.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: controller.allVerified
                  ? _kGreen.withOpacity(0.1)
                  : _kAmber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.allVerified
                  ? Icons.verified_rounded
                  : Icons.hourglass_top_rounded,
              color: controller.allVerified ? _kGreen : _kAmber,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.allVerified
                      ? 'All documents verified'
                      : '$verifiedCount of $total documents verified',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.allVerified
                      ? 'You\'re ready to start driving'
                      : 'Upload and verify to start accepting trips',
                  style: const TextStyle(fontSize: 12, color: _kTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.item,
    required this.isUploading,
    required this.onTap,
  });

  final DocumentItem item;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canRetry =
        item.status == DocumentStatus.notUploaded ||
        item.status == DocumentStatus.rejected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.status == DocumentStatus.rejected
              ? _kRed.withOpacity(0.3)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _Thumbnail(item: item, isUploading: isUploading),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.type.description,
                  style: const TextStyle(fontSize: 12, color: _kTextMuted),
                ),
                const SizedBox(height: 8),
                _StatusBadge(status: item.status),
                if (item.status == DocumentStatus.rejected &&
                    item.rejectionReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.rejectionReason!,
                    style: const TextStyle(fontSize: 11.5, color: _kRed),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isUploading)
            IconButton(
              onPressed: onTap,
              icon: Icon(
                canRetry ? Icons.upload_rounded : Icons.refresh_rounded,
                color: _kPurple,
              ),
              tooltip: canRetry ? 'Upload' : 'Re-upload',
            ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item, required this.isUploading});

  final DocumentItem item;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F7),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: isUploading
          ? const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPurple,
                ),
              ),
            )
          : item.localFilePath != null
          ? Image.file(File(item.localFilePath!), fit: BoxFit.cover)
          : Icon(_iconFor(item.type), color: _kTextMuted, size: 24),
    );
  }

  IconData _iconFor(DocumentType type) {
    switch (type) {
      case DocumentType.drivingLicense:
        return Icons.badge_outlined;
      case DocumentType.vehicleRc:
        return Icons.description_outlined;
      case DocumentType.aadhaar:
        return Icons.account_circle_outlined;
      case DocumentType.profilePhoto:
        return Icons.person_outline_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      DocumentStatus.notUploaded => (_kTextMuted, const Color(0xFFF3F3F7)),
      DocumentStatus.pending => (_kAmber, const Color(0xFFFEF6E0)),
      DocumentStatus.verified => (_kGreen, const Color(0xFFE7F8EE)),
      DocumentStatus.rejected => (_kRed, const Color(0xFFFCEAE9)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
