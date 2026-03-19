import 'package:emlakmaster_mobile/features/calls/data/device_call_log_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceCallLogSyncResult', () {
    test('enum has expected values', () {
      expect(DeviceCallLogSyncResult.values.length, 5);
      expect(DeviceCallLogSyncResult.values, contains(DeviceCallLogSyncResult.success));
      expect(DeviceCallLogSyncResult.values, contains(DeviceCallLogSyncResult.notSupported));
      expect(DeviceCallLogSyncResult.values, contains(DeviceCallLogSyncResult.error));
    });
  });

  group('DeviceCallLogSyncService', () {
    test('instance is singleton', () {
      expect(
        DeviceCallLogSyncService.instance,
        same(DeviceCallLogSyncService.instance),
      );
    });

    test('sync with empty advisorId returns error', () async {
      final result = await DeviceCallLogSyncService.instance.syncCallLogToFirestore('');
      expect(result, DeviceCallLogSyncResult.error);
    });

    test('hasCallLogPermission returns false when not Android (test VM)', () async {
      final has = await DeviceCallLogSyncService.instance.hasCallLogPermission();
      expect(has, isFalse);
    });

    test('sync with valid advisorId returns notSupported when not Android', () async {
      final result = await DeviceCallLogSyncService.instance.syncCallLogToFirestore('test-uid-123');
      expect(result, DeviceCallLogSyncResult.notSupported);
    });
  });
}
