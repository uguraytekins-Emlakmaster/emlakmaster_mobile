import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter/material.dart';

const _monthsTr = <String>[
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

const _weekdaysTr = <String>[
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

/// Liste bölüm başlığı — Bugün, Dün, hafta içi, tam tarih.
String callListSectionLabel(DateTime dateTime, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Bugün';
  if (diff == 1) return 'Dün';
  if (diff > 1 && diff < 7) {
    return _weekdaysTr[dateTime.weekday - 1];
  }
  return '${dateTime.day} ${_monthsTr[dateTime.month - 1]} ${dateTime.year}';
}

/// Sağ üst saat — 14:35
String callListTimeLabel(DateTime dateTime) {
  final h = dateTime.hour.toString().padLeft(2, '0');
  final m = dateTime.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

DateTime? callListCreatedAtForIndex({
  required int index,
  required List<LocalCallRecord> filteredLocals,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
}) {
  if (index < filteredLocals.length) {
    return DateTime.fromMillisecondsSinceEpoch(filteredLocals[index].createdAt);
  }
  final docIndex = index - filteredLocals.length;
  if (docIndex < 0 || docIndex >= filteredDocs.length) return null;
  return CrmCallRecordHelpers.createdAtOf(filteredDocs[docIndex].data());
}

bool callListShouldShowDateHeader({
  required int index,
  required List<LocalCallRecord> filteredLocals,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
}) {
  final current = callListCreatedAtForIndex(
    index: index,
    filteredLocals: filteredLocals,
    filteredDocs: filteredDocs,
  );
  if (current == null) return false;
  if (index == 0) return true;
  final previous = callListCreatedAtForIndex(
    index: index - 1,
    filteredLocals: filteredLocals,
    filteredDocs: filteredDocs,
  );
  if (previous == null) return true;
  return callListSectionLabel(current) != callListSectionLabel(previous);
}

String callListDateHeaderLabelForIndex({
  required int index,
  required List<LocalCallRecord> filteredLocals,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
}) {
  final dt = callListCreatedAtForIndex(
    index: index,
    filteredLocals: filteredLocals,
    filteredDocs: filteredDocs,
  );
  return dt == null ? '' : callListSectionLabel(dt);
}

/// iOS Phone tarzı gri bölüm başlığı.
class CallListDateSectionHeader extends StatelessWidget {
  const CallListDateSectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE8E8ED);
    final fg = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: fg,
          ),
        ),
      ),
    );
  }
}
