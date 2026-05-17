/// Tuş takımından görüşmeye geçerken taşınan ön tercihler.
class DialerControlPrefs {
  const DialerControlPrefs({
    this.muted = false,
    this.speakerOn = false,
    this.onHold = false,
  });

  final bool muted;
  final bool speakerOn;
  final bool onHold;

  DialerControlPrefs copyWith({
    bool? muted,
    bool? speakerOn,
    bool? onHold,
  }) {
    return DialerControlPrefs(
      muted: muted ?? this.muted,
      speakerOn: speakerOn ?? this.speakerOn,
      onHold: onHold ?? this.onHold,
    );
  }
}
