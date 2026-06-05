import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/services/auth_session_coordinator.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSessionCoordinator cross-session reset', () {
    test('bumpSessionEpoch increments authSessionEpoch and presentation epoch',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authSessionEpochProvider), 0);
      expect(container.read(authPresentationEpochProvider), 0);

      AuthSessionCoordinator.bumpSessionEpoch(
        _FakeWidgetRef(container),
      );

      expect(container.read(authSessionEpochProvider), 1);
      expect(container.read(authPresentationEpochProvider), 1);
    });

    test('resetForSignOut clears preferredConsultantPanel and shell shortcuts',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(preferredConsultantPanelProvider.notifier).state = true;
      container
          .read(mainShellShortcutProvider.notifier)
          .enqueue(MainShellShortcut.openHomeTab);

      AuthSessionCoordinator.resetForSignOut(
        _FakeWidgetRef(container),
        previousUid: 'old-uid',
      );

      expect(container.read(preferredConsultantPanelProvider), isNull);
      expect(container.read(mainShellShortcutProvider), isEmpty);
      expect(container.read(authSessionEpochProvider), 1);
    });

    test('prepareForLogin clears shell hints for new uid session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(overrideRoleProvider.notifier).state = null;
      container.read(preferredConsultantPanelProvider.notifier).state = false;

      AuthSessionCoordinator.prepareForLogin(
        _FakeWidgetRef(container),
        'new-uid',
      );

      expect(container.read(preferredConsultantPanelProvider), isNull);
      expect(container.read(authSessionEpochProvider), 1);
    });
  });
}

/// Minimal WidgetRef adapter for unit tests (coordinator only reads/writes providers).
class _FakeWidgetRef implements WidgetRef {
  _FakeWidgetRef(this._container);

  final ProviderContainer _container;

  @override
  BuildContext get context => throw UnimplementedError('test ref has no context');

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  bool exists(ProviderBase<Object?> provider) => _container.exists(provider);

  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    throw UnimplementedError();
  }

  @override
  ProviderSubscription<T> listenManual<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    throw UnimplementedError();
  }

  @override
  void invalidate(ProviderOrFamily provider) => _container.invalidate(provider);

  @override
  T refresh<T>(Refreshable<T> provider) => _container.refresh(provider);

  @override
  void notifyListeners() {}

  @override
  void onDispose(void Function() listener) {}

  @override
  void onCancel(void Function() listener) {}

  @override
  void onResume(void Function() listener) {}

  @override
  void onAddListener(void Function() listener) {}

  @override
  void onRemoveListener(void Function() listener) {}

  @override
  T watch<T>(ProviderListenable<T> provider) => _container.read(provider);
}
