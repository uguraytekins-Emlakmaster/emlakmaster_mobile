import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_list_operating_card.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_list_premium_tile.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter/material.dart';

/// Müşteri kartı — [CustomerListPremiumTile] + operating card kabuğu.
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.row,
    this.onTap,
    this.onCall,
    this.onMessage,
    this.onWhatsApp,
    this.onOpenDetail,
    this.selectionMode = false,
    this.isSelected = false,
  });

  final CustomerEntity customer;
  final CustomerListRowSnapshot row;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onOpenDetail;
  final bool selectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${customer.fullName} müşteri kartı',
      button: true,
      child: CustomerListOperatingCard(
        selected: isSelected,
        child: CustomerListPremiumTile(
          customer: customer,
          row: row,
          onTap: onTap,
          onCall: onCall,
          onMessage: onMessage,
          onWhatsApp: onWhatsApp,
          onOpenDetail: onOpenDetail,
          selectionMode: selectionMode,
          isSelected: isSelected,
        ),
      ),
    );
  }
}
