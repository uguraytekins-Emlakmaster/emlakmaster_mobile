/// Entegrasyon hataları — UI ve log için tek tip.
enum IntegrationErrorCode {
  unsupported,
  authExpired,
  rateLimited,
  malformedPayload,
  temporaryUnavailable,
  permissionDenied,
  reconnectRequired,
  unknown,
}
