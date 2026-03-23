import 'package:emlakmaster_mobile/features/auth/domain/auth_failure_kind.dart';
import 'package:emlakmaster_mobile/features/auth/domain/auth_result.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/utils/auth_result_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthCancelled has no banner and does not count as failure', () {
    const r = AuthCancelled();
    expect(r.loginBannerMessage, isNull);
    expect(r.shouldRecordLoginFailure, isFalse);
  });

  test('AuthFailure userCancelled does not count as failure', () {
    const r = AuthFailure(
      kind: AuthFailureKind.userCancelled,
      userMessage: '',
    );
    expect(r.shouldRecordLoginFailure, isFalse);
    expect(r.loginBannerMessage, isNull);
  });

  test('AuthFailure network shows banner', () {
    const r = AuthFailure(
      kind: AuthFailureKind.networkError,
      userMessage: 'Ağ hatası',
    );
    expect(r.loginBannerMessage, 'Ağ hatası');
    expect(r.shouldRecordLoginFailure, isTrue);
  });
}
