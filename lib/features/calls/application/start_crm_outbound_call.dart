import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Güvenilir CRM handoff — GSM devri + post-call taslak.
void startCrmOutboundCall(
  BuildContext context, {
  required String phone,
  String? customerId,
  required String startedFromScreen,
}) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return;
  context.push(
    AppRouter.routeCall,
    extra: <String, dynamic>{
      'phone': phone,
      if (customerId != null && customerId.trim().isNotEmpty)
        'customerId': customerId.trim(),
      'startedFromScreen': startedFromScreen,
    },
  );
}
