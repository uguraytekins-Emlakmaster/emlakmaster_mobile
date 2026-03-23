/// Oturum açıldıktan sonra [AppRouter.redirect] + provider’ların belirlediği hedef.
///
/// Uygulama içi gerçek yönlendirme `GoRouter` içinde merkezi; burada sadece isimlendirme.
enum PostAuthDestination {
  /// Onboarding tamamlanmadı → `/onboarding`
  needsOnboarding,

  /// Ofis / çalışma alanı kurulumu → `/workspace-setup`
  needsWorkspaceSetup,

  /// Firestore `users/{uid}` yok → rol seçimi → `/role-selection`
  needsRoleSelection,

  /// `users.officeId` yok → `/office` (oluştur / katıl)
  needsOfficeSetup,

  /// E-posta / `invited` üyelik (ileride)
  invitedPending,

  /// Ofis + üyelik hazır → ana kabuk
  officeReady,

  /// Doc + rol hazır (ofis öncesi) — eski isimlendirme ile uyum
  authenticatedReady,
}
