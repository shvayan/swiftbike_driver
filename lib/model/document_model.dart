enum DocumentType { drivingLicense, vehicleRc, aadhaar, profilePhoto }

extension DocumentTypeX on DocumentType {
  String get label => switch (this) {
    DocumentType.drivingLicense => 'Driving License',
    DocumentType.vehicleRc => 'Vehicle RC',
    DocumentType.aadhaar => 'Aadhaar',
    DocumentType.profilePhoto => 'Profile Photo',
  };

  String get description => switch (this) {
    DocumentType.drivingLicense => 'Front & back, clearly visible',
    DocumentType.vehicleRc => 'Registration certificate',
    DocumentType.aadhaar => 'Valid, unexpired card',
    DocumentType.profilePhoto => 'Clear face photo',
  };

  String get apiKey => switch (this) {
    DocumentType.drivingLicense => 'DRIVING_LICENSE',
    DocumentType.vehicleRc => 'VEHICLE_RC',
    DocumentType.aadhaar => 'AADHAAR',
    DocumentType.profilePhoto => 'PROFILE_PHOTO',
  };
}

enum DocumentStatus { notUploaded, pending, verified, rejected }

extension DocumentStatusX on DocumentStatus {
  String get label => switch (this) {
    DocumentStatus.notUploaded => 'Not uploaded',
    DocumentStatus.pending => 'Under review',
    DocumentStatus.verified => 'Verified',
    DocumentStatus.rejected => 'Rejected',
  };

  static DocumentStatus fromApi(String? value) {
    switch (value) {
      case 'PENDING':
        return DocumentStatus.pending;
      case 'VERIFIED':
        return DocumentStatus.verified;
      case 'REJECTED':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.notUploaded;
    }
  }
}

class DocumentItem {
  DocumentItem({
    required this.type,
    this.status = DocumentStatus.notUploaded,
    this.imageUrl,
    this.rejectionReason,
    this.localFilePath,
  });

  final DocumentType type;
  DocumentStatus status;
  String? imageUrl;
  String? rejectionReason;
  String? localFilePath; // preview before upload confirms

  DocumentItem copyWith({
    DocumentStatus? status,
    String? imageUrl,
    String? rejectionReason,
    String? localFilePath,
  }) {
    return DocumentItem(
      type: type,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
