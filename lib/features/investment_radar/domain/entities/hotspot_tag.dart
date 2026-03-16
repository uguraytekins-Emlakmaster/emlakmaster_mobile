import 'package:equatable/equatable.dart';

/// Yatırım Radarı: altyapı / bölge güncellemesi (metro, hastane, imar).
class HotspotTag with EquatableMixin {
  const HotspotTag({
    required this.id,
    required this.label,
    this.regionId,
    this.regionName,
    this.highYieldPotential = false,
    this.source,
    this.updatedAt,
  });

  final String id;
  final String label;
  final String? regionId;
  final String? regionName;
  final bool highYieldPotential;
  final String? source;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, label];
}
