import 'package:emlakmaster_mobile/core/config/google_oauth_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('webClientId looks like Google OAuth Web client id', () {
    const id = GoogleOAuthConstants.webClientId;
    expect(id, endsWith('.apps.googleusercontent.com'));
    expect(id.contains('-'), isTrue);
    expect(id.length, greaterThan(30));
  });

  test('iosClientId looks like Google OAuth iOS client id', () {
    const id = GoogleOAuthConstants.iosClientId;
    expect(id, endsWith('.apps.googleusercontent.com'));
    expect(id.contains('-'), isTrue);
    expect(id.length, greaterThan(30));
  });

  test('web and iOS client ids are different (Web vs iOS)', () {
    expect(
      GoogleOAuthConstants.webClientId,
      isNot(equals(GoogleOAuthConstants.iosClientId)),
    );
  });
}
