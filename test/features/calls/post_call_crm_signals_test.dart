import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extractPostCallCrmSignals detects appointment and price objection', () {
    final s = extractPostCallCrmSignals(
      'Müşteri yarın ofise gelecek ama fiyat pahalı dedi, indirim istedi.',
    );
    expect(s.appointmentMentioned, isTrue);
    expect(s.priceObjection, isTrue);
    expect(s.nextActionHint, contains('Fiyat'));
  });

  test('extractPostCallCrmSignals high urgency from bugün', () {
    final s = extractPostCallCrmSignals('Bugün dönüş bekliyor, çok istekli.');
    expect(s.followUpUrgency, PostCallCrmSignals.urgencyHigh);
    expect(s.interestLevel, PostCallCrmSignals.interestHigh);
  });
}
