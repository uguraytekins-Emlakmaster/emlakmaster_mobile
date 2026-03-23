import 'package:equatable/equatable.dart';

/// Phase 1.4 — kart üzerinde gösterilen yetenek satırı (✔️ / ❌ / ⚠️).
class PlatformUiCapabilities extends Equatable {
  const PlatformUiCapabilities({
    required this.canImportListings,
    required this.canUpdatePrice,
    required this.canManageMessages,
    required this.canSync,
  });

  final bool canImportListings;
  final bool canUpdatePrice;

  /// Mesaj okuma / yanıtlama (platform politikasına göre birleşik bayrak).
  final bool canManageMessages;
  final bool canSync;

  @override
  List<Object?> get props => [
        canImportListings,
        canUpdatePrice,
        canManageMessages,
        canSync,
      ];
}
