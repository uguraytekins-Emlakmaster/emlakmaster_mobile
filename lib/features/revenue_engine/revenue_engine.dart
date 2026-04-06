/// Gelir motoru — kural tabanlı lead skoru, takip önerisi, danışman performansı, özetim kartları.
///
/// **Entegrasyon noktaları**
/// - Girdi: [customerListForAgentProvider], [consultantCallsStreamProvider],
///   [localCallRecordsStreamProvider], [advisorTasksMetaProvider],
///   [syncDelayedRiskCustomerIdsProvider].
/// - Çıktı: [customerRevenueSignalsMapProvider], [revenueDashboardSnapshotProvider].
/// - UI: [RevenueIntelligenceDashboardSection] (danışman özetim).
/// - Mevcut Lead Temperature Engine ile çakışmaz; bu katman CRM gelir odaklıdır.
library;

export 'package:emlakmaster_mobile/features/revenue_engine/data/customer_revenue_signals_builder.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/domain/consultant_performance_engine.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/domain/customer_signal_inputs.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/domain/follow_up_recommendation_engine.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/domain/high_value_ranking.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/domain/lead_score_engine.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/consultant_performance_strip.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/customer_revenue_intelligence_strip.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/manager_revenue_summary_card.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_customer_row_badges.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_intelligence_dashboard_section.dart';
export 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_ui_formatters.dart';
