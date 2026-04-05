import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// İlk giriş: ofis oluştur / ofise katıl → isteğe bağlı platform bağlantısı.
class WorkspaceSetupPage extends StatefulWidget {
  const WorkspaceSetupPage({super.key});

  @override
  State<WorkspaceSetupPage> createState() => _WorkspaceSetupPageState();
}

class _WorkspaceSetupPageState extends State<WorkspaceSetupPage> {
  final PageController _controller = PageController();
  int _page = 0;
  _WorkspaceIntent? _intent;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await OnboardingStore.instance.setWorkspaceSetupCompleted();
    if (!mounted) return;
    context.go(AppRouter.routeRoleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  if (_page > 0)
                    IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _controller.previousPage(
                          duration: DesignTokens.durationNormal,
                          curve: Curves.easeOutCubic,
                        );
                      },
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: ext.foregroundMuted, size: 20),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Rainbow CRM',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ext.foregroundMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                child: LinearProgressIndicator(
                  value: (_page + 1) / 2,
                  minHeight: 4,
                  backgroundColor: ext.border.withValues(alpha: 0.6),
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _StepOfficeChoice(
                    selected: _intent,
                    onSelect: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _intent = v);
                    },
                    onNext: _intent == null
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            _controller.nextPage(
                              duration: DesignTokens.durationNormal,
                              curve: Curves.easeOutCubic,
                            );
                          },
                  ),
                  _StepPlatforms(
                    intent: _intent,
                    onContinue: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _WorkspaceIntent { create, join }

class _StepOfficeChoice extends StatelessWidget {
  const _StepOfficeChoice({
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  final _WorkspaceIntent? selected;
  final void Function(_WorkspaceIntent) onSelect;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          'Ofisinizi kurun',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ext.foreground,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Yeni bir ofis oluşturun veya davet koduyla mevcut bir ekibe katılın. Sonraki adımda harici ilan platformlarını bağlayabilirsiniz.',
          style: TextStyle(color: ext.foregroundSecondary, height: 1.45, fontSize: 14),
        ),
        const SizedBox(height: 28),
        _ChoiceTile(
          icon: Icons.add_business_rounded,
          title: 'Ofis oluştur',
          subtitle: 'Yeni bir ofis ve ekip alanı açın.',
          selected: selected == _WorkspaceIntent.create,
          onTap: () => onSelect(_WorkspaceIntent.create),
        ),
        const SizedBox(height: 12),
        _ChoiceTile(
          icon: Icons.group_add_rounded,
          title: 'Ofise katıl',
          subtitle: 'Yöneticinizden aldığınız davet ile ekibe girin.',
          selected: selected == _WorkspaceIntent.join,
          onTap: () => onSelect(_WorkspaceIntent.join),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: ext.brandPrimary,
            foregroundColor: ext.onBrand,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            ),
          ),
          child: const Text('Devam', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: DesignTokens.durationFast,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: selected ? scheme.primary.withValues(alpha: 0.65) : ext.border.withValues(alpha: 0.7),
          width: selected ? 1.5 : 1,
        ),
        color: selected ? scheme.primary.withValues(alpha: 0.08) : ext.surfaceElevated,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: ext.foreground,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: ext.foregroundSecondary, fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? scheme.primary : ext.foregroundMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepPlatforms extends StatelessWidget {
  const _StepPlatforms({
    required this.intent,
    required this.onContinue,
  });

  final _WorkspaceIntent? intent;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hint = intent == _WorkspaceIntent.join
        ? 'Davet kodunuz varsa ekip ataması sonraki adımda tamamlanır.'
        : 'Ofis oluşturduktan sonra yönetici panelinden ekibinizi yönetebilirsiniz.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          'Harici platformlar',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ext.foreground,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sahibinden, Hepsiemlak ve Emlakjet bağlantıları ofis yöneticisi tarafından Ayarlar → Platform bağlantıları üzerinden kurulur; senkron ilanlar danışmanlara «İlanlar» ve ilgili ekranlarda görünür.',
          style: TextStyle(color: ext.foregroundSecondary, height: 1.45, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: ext.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: ext.foregroundMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(hint, style: TextStyle(color: ext.foregroundSecondary, fontSize: 13, height: 1.35)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: ext.onBrand,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            ),
          ),
          child: const Text('Devam', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
