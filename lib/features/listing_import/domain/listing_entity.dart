import 'package:equatable/equatable.dart';

/// Birleşik ilan modeli — import motoru + CRM listesi (API’ye hazır).
class ListingEntity extends Equatable {
  const ListingEntity({
    required this.id,
    required this.ownerUserId,
    required this.title,
    required this.price,
    required this.location,
    required this.description,
    required this.images,
    required this.platformId,
    required this.createdAt,
    required this.updatedAt,
    this.duplicateGroupId,
    this.sourceUrl,
    this.importTaskId,
    this.isFavorite = false,
    this.quickNote,
  });

  final String id;
  final String ownerUserId;
  final String title;
  final double price;
  final String location;
  final String description;
  final List<String> images;
  /// sahibinden | hepsiemlak | emlakjet | manual | file
  final String platformId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? duplicateGroupId;
  final String? sourceUrl;
  final String? importTaskId;
  final bool isFavorite;
  final String? quickNote;

  ListingEntity copyWith({
    String? id,
    String? ownerUserId,
    String? title,
    double? price,
    String? location,
    String? description,
    List<String>? images,
    String? platformId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? duplicateGroupId,
    String? sourceUrl,
    String? importTaskId,
    bool? isFavorite,
    String? quickNote,
  }) {
    return ListingEntity(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      title: title ?? this.title,
      price: price ?? this.price,
      location: location ?? this.location,
      description: description ?? this.description,
      images: images ?? this.images,
      platformId: platformId ?? this.platformId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      duplicateGroupId: duplicateGroupId ?? this.duplicateGroupId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      importTaskId: importTaskId ?? this.importTaskId,
      isFavorite: isFavorite ?? this.isFavorite,
      quickNote: quickNote ?? this.quickNote,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerUserId,
        title,
        price,
        location,
        duplicateGroupId,
        importTaskId,
        isFavorite,
      ];
}
