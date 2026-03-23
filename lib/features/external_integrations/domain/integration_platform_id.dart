/// Harici ilan platformu — adapter registry anahtarı.
enum IntegrationPlatformId {
  sahibinden('sahibinden', 'Sahibinden.com'),
  hepsiemlak('hepsiemlak', 'Hepsiemlak'),
  emlakjet('emlakjet', 'Emlakjet');

  const IntegrationPlatformId(this.storageKey, this.displayName);
  final String storageKey;
  final String displayName;

  static IntegrationPlatformId? tryParse(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final v in IntegrationPlatformId.values) {
      if (v.storageKey == key) return v;
    }
    return null;
  }
}
