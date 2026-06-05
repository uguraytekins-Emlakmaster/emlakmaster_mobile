import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/screens/role_based_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveShellKind', () {
    test('agent ALWAYS resolves to consultant shell (preferConsultant=false)',
        () {
      // Sızıntı testi: panel toggle false olsa bile agent admin kabuğuna giremez.
      expect(
        resolveShellKind(AppRole.agent, false),
        ResolvedShellKind.consultant,
      );
    });

    test('agent resolves to consultant shell for any toggle value', () {
      expect(resolveShellKind(AppRole.agent, null),
          ResolvedShellKind.consultant);
      expect(resolveShellKind(AppRole.agent, true),
          ResolvedShellKind.consultant);
      expect(resolveShellKind(AppRole.agent, false),
          ResolvedShellKind.consultant);
    });

    test('guest never reaches admin shell', () {
      expect(resolveShellKind(AppRole.guest, false),
          ResolvedShellKind.consultant);
    });

    test('real admin defaults to admin shell', () {
      expect(resolveShellKind(AppRole.brokerOwner, null),
          ResolvedShellKind.admin);
      expect(resolveShellKind(AppRole.officeManager, null),
          ResolvedShellKind.admin);
      expect(resolveShellKind(AppRole.superAdmin, false),
          ResolvedShellKind.admin);
    });

    test('real admin may opt into consultant view (toggle=true)', () {
      expect(resolveShellKind(AppRole.brokerOwner, true),
          ResolvedShellKind.consultant);
      expect(resolveShellKind(AppRole.officeManager, true),
          ResolvedShellKind.consultant);
    });
  });
}
