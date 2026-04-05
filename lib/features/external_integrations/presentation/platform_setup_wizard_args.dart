import '../domain/integration_platform_id.dart';

/// [GoRouter] `extra` — yönetici kurulum sihirbazı.
class PlatformSetupWizardArgs {
  const PlatformSetupWizardArgs({
    this.initialPlatform,
    this.editMode = false,
  });

  final IntegrationPlatformId? initialPlatform;
  final bool editMode;
}
