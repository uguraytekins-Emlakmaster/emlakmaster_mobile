import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `offices/{id}`.
class Office {
  const Office({
    required this.id,
    required this.name,
    required this.createdBy,
    this.createdAt,
    this.isActive = true,
    this.planType = 'standard',
    this.settings = const {},
    this.logoUrl,
    this.logoStoragePath,
    this.logoMimeType,
    this.logoSizeBytes,
    this.logoUploadedAt,
    this.logoOwnerUserId,
  });

  final String id;
  final String name;
  final String createdBy;
  final DateTime? createdAt;
  final bool isActive;
  /// İleride faturalama / paket.
  final String planType;
  final Map<String, dynamic> settings;

  /// Firebase Storage ofis logosu (okuma: tüm ofis üyeleri).
  final String? logoUrl;
  final String? logoStoragePath;
  final String? logoMimeType;
  final int? logoSizeBytes;
  final DateTime? logoUploadedAt;
  final String? logoOwnerUserId;

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'name': name,
      'createdBy': createdBy,
      'isActive': isActive,
      'planType': planType,
      'settings': settings,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Office? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    return Office(
      id: id,
      name: data['name'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _ts(data['createdAt']),
      isActive: data['isActive'] as bool? ?? true,
      planType: data['planType'] as String? ?? 'standard',
      settings: Map<String, dynamic>.from(
        data['settings'] as Map? ?? const {},
      ),
      logoUrl: data['logoUrl'] as String?,
      logoStoragePath: data['logoStoragePath'] as String?,
      logoMimeType: data['logoMimeType'] as String?,
      logoSizeBytes: (data['logoSizeBytes'] as num?)?.toInt(),
      logoUploadedAt: _ts(data['logoUploadedAt']),
      logoOwnerUserId: data['logoOwnerUserId'] as String?,
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
