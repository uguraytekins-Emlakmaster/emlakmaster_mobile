import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/models/follow_up_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/follow_up_list_operating_card.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/follow_up_list_premium_tile.dart';
import 'package:flutter/material.dart';

class FollowUpLeadCard extends StatelessWidget {
  const FollowUpLeadCard({
    super.key,
    required this.item,
    required this.snapshot,
    this.onTap,
    this.onCall,
    this.onWhatsApp,
    this.onOpenCustomer,
    this.onCreateTask,
    this.onSnooze,
    this.onDetail,
  });

  final ResurrectionQueueItem item;
  final FollowUpRowSnapshot snapshot;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onOpenCustomer;
  final VoidCallback? onCreateTask;
  final VoidCallback? onSnooze;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${snapshot.displayName} takip kaydı',
      button: true,
      child: FollowUpListOperatingCard(
        emphasizeUrgent: snapshot.emphasizeUrgent,
        child: FollowUpListPremiumTile(
          item: item,
          snapshot: snapshot,
          onTap: onTap,
          onCall: onCall,
          onWhatsApp: onWhatsApp,
          onOpenCustomer: onOpenCustomer,
          onCreateTask: onCreateTask,
          onSnooze: onSnooze,
          onDetail: onDetail,
        ),
      ),
    );
  }
}
