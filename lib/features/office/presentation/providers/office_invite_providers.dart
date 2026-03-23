import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/office_invite_repository.dart';
import '../../domain/office_invite_entity.dart';

/// Davet kodu önizleme (doğrulama öncesi — tam doğrulama transaction’da).
final invitePreviewProvider =
    FutureProvider.family<OfficeInvite?, String>((ref, rawCode) async {
  final c = rawCode.trim();
  if (c.length < 4) return null;
  return OfficeInviteRepository.findActiveInviteByCode(c);
});
