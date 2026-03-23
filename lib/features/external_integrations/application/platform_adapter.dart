import '../domain/external_connection_entity.dart';
import '../domain/integration_platform_id.dart';
import '../domain/integration_result.dart';

/// Harici platform adapter sözleşmesi — desteklenmeyenler [IntegrationUnsupported] döner.
abstract class PlatformAdapter {
  IntegrationPlatformId get platformId;

  Future<IntegrationResult<void>> connect();

  Future<IntegrationResult<void>> disconnect(String connectionId);

  Future<IntegrationResult<bool>> validateConnection(String connectionId);

  Future<IntegrationResult<List<Object>>> fetchListings({String? cursor});

  Future<IntegrationResult<void>> syncListings(String connectionId);

  Future<IntegrationResult<List<Object>>> fetchMessages({String? cursor});

  Future<IntegrationResult<void>> sendReply(String conversationId, String body);

  Future<IntegrationResult<void>> updateListing(
    String externalListingId, {
    double? price,
    String? status,
  });

  ExternalConnectionEntity? mapRawConnection(Map<String, dynamic> raw);
}
