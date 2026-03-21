/// Rainbow Investment Intelligence — modül giriş noktası.
///
/// - [RainbowAnalyticsCenterPage] — ana akış
/// - [IntelReportHistoryPage] — geçmiş raporlar
/// - [RainbowIntelService] — Firestore + skor + PDF
library analytics;

export 'data/intel_report_history_repository.dart';
export 'data/rainbow_intel_service.dart';
export 'domain/models/rainbow_intel_models.dart';
export 'domain/rainbow_score_engine.dart';
export 'presentation/pages/intel_report_history_page.dart';
export 'presentation/pages/rainbow_analytics_center_page.dart';
export 'presentation/providers/rainbow_intel_providers.dart';
export 'presentation/widgets/rainbow_analytics_center_card.dart';
