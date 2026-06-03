import 'package:emlakmaster_mobile/features/calls/domain/call_session_reliability.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';

/// Çağrı kaynağı güven göstergesi — görsel, abartısız.
enum CallConfidenceKind {
  portivoOriginated,
  manualRecord,
  callbackPending,
  deviceLog,
}

abstract final class CallConfidenceLabels {
  CallConfidenceLabels._();

  static String label(CallConfidenceKind kind) {
    return switch (kind) {
      CallConfidenceKind.portivoOriginated => 'Portivo CRM\'den arandı',
      CallConfidenceKind.manualRecord => 'Manuel kayıt',
      CallConfidenceKind.callbackPending => 'Geri arama bekliyor',
      CallConfidenceKind.deviceLog => 'Cihaz kaydı',
    };
  }

  static CallConfidenceKind? fromStartedFromScreen(String? screen) {
    final s = screen?.trim() ?? '';
    if (s == 'identity_sheet_raw_dial' || s == 'device_call_log') {
      return CallConfidenceKind.deviceLog;
    }
    if (s.isEmpty || s == 'unknown') return CallConfidenceKind.manualRecord;
    return CallConfidenceKind.portivoOriginated;
  }

  /// Kart rozeti — yalnızca anlamlı olduğunda; hafıza ipucu ile çift göstermez.
  static CallConfidenceKind? resolveForRecord({
    String? startedFromScreen,
    String? outcome,
    String? quickOutcomeCode,
    String? memoryHint,
  }) {
    final oc = (quickOutcomeCode ?? outcome ?? '').trim();
    final screen = startedFromScreen?.trim() ?? '';
    final hint = memoryHint?.trim() ?? '';

    if (oc == QuickCallOutcome.callbackScheduled) {
      if (hint == 'Geri arama bekliyor') return null;
      return CallConfidenceKind.callbackPending;
    }

    if (screen == 'device_call_log' || screen == 'identity_sheet_raw_dial') {
      return CallConfidenceKind.deviceLog;
    }

    if (CallSessionReliability.isReliableHandoffSource(screen)) {
      return CallConfidenceKind.portivoOriginated;
    }

    if (screen.isEmpty || screen == 'unknown') {
      if (oc.isEmpty || oc == QuickCallOutcome.noCaptureYet) {
        return CallConfidenceKind.manualRecord;
      }
      return null;
    }

    return null;
  }
}
