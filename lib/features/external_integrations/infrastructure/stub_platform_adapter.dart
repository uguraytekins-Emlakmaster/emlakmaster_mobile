import '../application/platform_adapter.dart';
import '../domain/external_connection_entity.dart';
import '../domain/integration_error_code.dart';
import '../domain/integration_platform_id.dart';
import '../domain/integration_result.dart';

/// Phase 1: gerçek OAuth/API yok; tüm çağrılar typed stub.
class StubPlatformAdapter extends PlatformAdapter {
  StubPlatformAdapter(this.platformId);

  @override
  final IntegrationPlatformId platformId;

  @override
  Future<IntegrationResult<void>> connect() async {
    return const IntegrationUnsupported('connect');
  }

  @override
  Future<IntegrationResult<void>> disconnect(String connectionId) async {
    return const IntegrationUnsupported('disconnect');
  }

  @override
  Future<IntegrationResult<bool>> validateConnection(String connectionId) async {
    return const IntegrationUnsupported('validateConnection');
  }

  @override
  Future<IntegrationResult<List<Object>>> fetchListings({String? cursor}) async {
    return const IntegrationUnsupported('fetchListings');
  }

  @override
  Future<IntegrationResult<void>> syncListings(String connectionId) async {
    return const IntegrationUnsupported('syncListings');
  }

  @override
  Future<IntegrationResult<List<Object>>> fetchMessages({String? cursor}) async {
    return const IntegrationUnsupported('fetchMessages');
  }

  @override
  Future<IntegrationResult<void>> sendReply(String conversationId, String body) async {
    return const IntegrationUnsupported('sendReply');
  }

  @override
  Future<IntegrationResult<void>> updateListing(
    String externalListingId, {
    double? price,
    String? status,
  }) async {
    return const IntegrationUnsupported('updateListing');
  }

  @override
  ExternalConnectionEntity? mapRawConnection(Map<String, dynamic> raw) => null;
}

/// Sahte hata dönen adapter — hata UI testleri için.
class FailingStubAdapter extends StubPlatformAdapter {
  FailingStubAdapter(super.platformId);

  @override
  Future<IntegrationResult<void>> connect() async {
    return const IntegrationFailure(IntegrationErrorCode.temporaryUnavailable, 'Stub');
  }
}
