import '../domain/integration_platform_id.dart';
import '../infrastructure/stub_platform_adapter.dart';
import 'platform_adapter.dart';

/// Platform kimliğine göre adapter çözümü (ileride DI ile değiştirilebilir).
class IntegrationProvider {
  IntegrationProvider._();

  static final Map<IntegrationPlatformId, PlatformAdapter> _adapters = {
    for (final p in IntegrationPlatformId.values)
      p: StubPlatformAdapter(p),
  };

  static PlatformAdapter adapterFor(IntegrationPlatformId id) =>
      _adapters[id] ?? StubPlatformAdapter(id);
}
