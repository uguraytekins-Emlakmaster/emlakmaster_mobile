import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/resurrection_lead_topic_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class FollowUpListActions {
  FollowUpListActions._();

  static void openDetail(
    BuildContext context, {
    required ResurrectionQueueItem item,
  }) {
    AppFeedback.lightImpact();
    showResurrectionLeadTopicSheet(
      context,
      topicTitle: 'Takip Merkezi',
      item: item,
    );
  }

  static void openCustomer(BuildContext context, ResurrectionQueueItem item) {
    AppFeedback.lightImpact();
    context.push(
      AppRouter.routeCustomerDetail.replaceFirst(':id', item.customerId),
    );
  }

  static void launchCall(BuildContext context, ResurrectionQueueItem item) {
    final phone = item.primaryPhone?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arama için telefon numarası yok.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    AppFeedback.mediumImpact();
    startCrmOutboundCall(
      context,
      phone: phone,
      customerId: item.customerId,
      startedFromScreen: 'follow_up_center',
    );
  }

  static Future<void> launchWhatsApp(
    BuildContext context,
    ResurrectionQueueItem item,
  ) async {
    final phone = item.primaryPhone?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp için telefon numarası yok.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    AppFeedback.lightImpact();
    final ok = await WhatsAppLauncher.openChat(phone);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp açılamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> createTask(
    BuildContext context,
    WidgetRef ref,
    ResurrectionQueueItem item, {
    String title = 'Takip et',
    Duration dueIn = const Duration(days: 1),
  }) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    AppFeedback.mediumImpact();
    try {
      await FirestoreService.setTask({
        'advisorId': uid,
        'customerId': item.customerId,
        'title': title,
        'dueAt': Timestamp.fromDate(DateTime.now().add(dueIn)),
        'done': false,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev oluşturuldu: $title'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingErrorMessage(e, context: 'follow_up_task'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on StateError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingErrorMessage(e, context: 'follow_up_task'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Future<void> snooze(
    BuildContext context,
    WidgetRef ref,
    ResurrectionQueueItem item,
  ) =>
      createTask(
        context,
        ref,
        item,
        title: 'Takip ertelendi',
        dueIn: const Duration(days: 3),
      );
}
