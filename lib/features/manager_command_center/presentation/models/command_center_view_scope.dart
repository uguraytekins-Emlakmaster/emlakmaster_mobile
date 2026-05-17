/// Komuta merkezi liste görünüm modu.
enum CommandCenterViewScope {
  all,
  consultant,
  customer,
  pending,
}

extension CommandCenterViewScopeLabels on CommandCenterViewScope {
  String get labelTr {
    switch (this) {
      case CommandCenterViewScope.all:
        return 'Tüm kayıtlar';
      case CommandCenterViewScope.consultant:
        return 'Danışman';
      case CommandCenterViewScope.customer:
        return 'Müşteri';
      case CommandCenterViewScope.pending:
        return 'Eksik kayıt';
    }
  }
}
