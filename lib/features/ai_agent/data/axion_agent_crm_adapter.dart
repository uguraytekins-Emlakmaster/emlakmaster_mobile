import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';

/// CRM → Axion Agent adapter'ı.
///
/// Mevcut repository/entity'lere DOKUNMAZ; yalnızca gerçek CRM verisini
/// saf snapshot DTO'larına map eder. Sıcaklık, mevcut kural tabanlı
/// [computeCustomerHeat] motorundan türetilir (AI değil).
abstract final class AxionAgentCrmAdapter {
  static AxionCustomerSnapshot customerFrom(CustomerEntity c) {
    final heat = computeCustomerHeat(c);
    return AxionCustomerSnapshot(
      id: c.id,
      name: c.fullName?.trim() ?? '',
      phone: c.primaryPhone,
      region:
          c.regionPreferences.isNotEmpty ? c.regionPreferences.first : null,
      budgetMin: c.budgetMin,
      budgetMax: c.budgetMax,
      intent: c.customerType?.name,
      temperature: switch (heat.heatLevel) {
        CustomerHeatLevel.hot => AxionCustomerTemperature.hot,
        CustomerHeatLevel.warm => AxionCustomerTemperature.warm,
        CustomerHeatLevel.cool ||
        CustomerHeatLevel.cold =>
          AxionCustomerTemperature.cold,
      },
      lastContactAt: c.lastInteractionAt,
      preferredDistricts: c.regionPreferences,
      updatedAt: c.updatedAt,
    );
  }

  static AxionTaskSnapshot taskFromDoc(String id, Map<String, dynamic> data) {
    final cid = (data['customerId'] as String?)?.trim();
    return AxionTaskSnapshot(
      id: id,
      customerId: (cid != null && cid.isNotEmpty) ? cid : null,
      title: (data['title'] as String?)?.trim() ?? '',
      isCompleted: data['done'] == true,
      isFollowUp: data['isFollowUp'] == true || data['type'] == 'follow_up',
      dueAt: (data['dueAt'] as Timestamp?)?.toDate() ??
          (data['dueDate'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static AxionCallSnapshot? callFromDoc(String id, Map<String, dynamic> data) {
    final at = CrmCallRecordHelpers.createdAtOf(data);
    if (at == null) return null;
    return AxionCallSnapshot(
      id: id,
      customerId: CrmCallRecordHelpers.customerIdOf(data),
      phoneNumber:
          data['phoneNumber'] as String? ?? data['phone'] as String?,
      contactName: _contactNameOf(data),
      isMissedOrNoAnswer: CrmCallRecordHelpers.isMissedOutcome(data),
      at: at,
    );
  }

  /// Çağrı dokümanındaki rehber/kişi ismi (cihaz senkronundan gelir).
  static String? _contactNameOf(Map<String, dynamic> data) {
    for (final key in <String>[
      'contactDisplayName',
      'contactName',
      'callerName',
    ]) {
      final v = data[key] as String?;
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
