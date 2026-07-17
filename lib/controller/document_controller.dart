import 'dart:io';
import 'package:flutter/foundation.dart';

import '../model/document_model.dart';

class DocumentController extends ChangeNotifier {
  DocumentController({required this.token, required this.driverId});

  final String? token;
  final String? driverId;

  bool isLoadingList = true;
  String? message;

  final Map<DocumentType, DocumentItem> documents = {
    for (final type in DocumentType.values) type: DocumentItem(type: type),
  };

  // Tracks which single document is currently uploading (for per-card spinner)
  DocumentType? uploadingType;

  bool get allVerified =>
      documents.values.every((d) => d.status == DocumentStatus.verified);

  Future<void> fetchStatus() async {
    isLoadingList = true;
    notifyListeners();

    try {
      // TODO: replace with real GET /driver/documents call using `token`/`driverId`
      final response = await _mockFetchStatus();
      for (final entry in response.entries) {
        documents[entry.key] = documents[entry.key]!.copyWith(
          status: entry.value.status,
          imageUrl: entry.value.imageUrl,
          rejectionReason: entry.value.rejectionReason,
        );
      }
    } catch (_) {
      message = 'Could not load document status.';
    } finally {
      isLoadingList = false;
      notifyListeners();
    }
  }

  Future<void> uploadDocument(DocumentType type, File file) async {
    uploadingType = type;
    documents[type] = documents[type]!.copyWith(localFilePath: file.path);
    notifyListeners();

    try {
      // TODO: replace with real multipart POST /driver/documents/upload
      // using MultipartFile.fromPath('file', file.path) + type.apiKey
      await Future.delayed(const Duration(seconds: 1));
      documents[type] = documents[type]!.copyWith(
        status: DocumentStatus.pending,
        imageUrl: file.path,
      );
    } catch (_) {
      message = 'Upload failed for ${type.label}. Please try again.';
    } finally {
      uploadingType = null;
      notifyListeners();
    }
  }

  // Placeholder — remove once wired to your real API client.
  Future<Map<DocumentType, DocumentItem>> _mockFetchStatus() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      DocumentType.drivingLicense: DocumentItem(
        type: DocumentType.drivingLicense,
        status: DocumentStatus.pending,
      ),
      DocumentType.vehicleRc: DocumentItem(
        type: DocumentType.vehicleRc,
        status: DocumentStatus.notUploaded,
      ),
      DocumentType.aadhaar: DocumentItem(
        type: DocumentType.aadhaar,
        status: DocumentStatus.rejected,
        rejectionReason: 'Image blurry, please re-upload',
      ),
      DocumentType.profilePhoto: DocumentItem(
        type: DocumentType.profilePhoto,
        status: DocumentStatus.verified,
      ),
    };
  }
}
