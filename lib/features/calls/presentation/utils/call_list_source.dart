/// Çağrı geçmişi kaynak filtresi — CRM / bu cihaz taslakları.
enum CallListSource {
  all,
  crmOnly,
  deviceDraft,
}

extension CallListSourceLabels on CallListSource {
  String get labelTr {
    switch (this) {
      case CallListSource.all:
        return 'Tümü';
      case CallListSource.crmOnly:
        return 'CRM';
      case CallListSource.deviceDraft:
        return 'Bu cihaz';
    }
  }
}
