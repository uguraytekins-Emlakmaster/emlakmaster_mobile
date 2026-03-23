import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/office_invite_repository.dart';
import '../../data/office_membership_repository.dart';
import '../../domain/office_invite_entity.dart';
import '../../domain/office_membership_entity.dart';

final officeMembersStreamProvider =
    StreamProvider.family<List<OfficeMembership>, String>((ref, officeId) {
  return OfficeMembershipRepository.watchMembershipsForOffice(officeId);
});

final officeInvitesStreamProvider =
    StreamProvider.family<List<OfficeInvite>, String>((ref, officeId) {
  return OfficeInviteRepository.watchInvitesForOffice(officeId);
});
