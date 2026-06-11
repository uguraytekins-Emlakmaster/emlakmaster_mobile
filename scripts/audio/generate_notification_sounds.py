#!/usr/bin/env python3
"""Axion CRM — özel bildirim sesleri üretici.

Sistem bildirim kanalları (Android res/raw) için şık, markaya özel
zil sesleri sentezler. Saf Python (stdlib) — bağımlılık yok.

Tasarım dili: cam çan / marimba hibriti; yumuşak atak, doğal sönüm,
inharmonik parsiyeller (gerçek çan fiziği). Kısa, zarif, rahatsız etmez.

Çalıştırma:
    python3 scripts/audio/generate_notification_sounds.py
Çıktı:
    android/app/src/main/res/raw/*.wav
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100


def bell_note(freq, duration, partials, attack=0.008, brightness=1.0):
    """Tek çan notası: (oran, genlik, sönüm hızı) parsiyel listesiyle."""
    n = int(SAMPLE_RATE * duration)
    out = [0.0] * n
    for ratio, amp, decay in partials:
        f = freq * ratio
        if f > SAMPLE_RATE / 2.2:  # aliasing koruması
            continue
        a = amp * (brightness if ratio > 1.5 else 1.0)
        phase = 0.0
        step = 2.0 * math.pi * f / SAMPLE_RATE
        for i in range(n):
            t = i / SAMPLE_RATE
            env = math.exp(-decay * t)
            out[i] += a * env * math.sin(phase)
            phase += step
    # Yumuşak atak (raised cosine) + kuyruk sönümü
    a_n = max(1, int(SAMPLE_RATE * attack))
    for i in range(min(a_n, n)):
        out[i] *= 0.5 - 0.5 * math.cos(math.pi * i / a_n)
    f_n = max(1, int(SAMPLE_RATE * 0.05))
    for i in range(f_n):
        out[n - 1 - i] *= i / f_n
    return out


def mix(*layers):
    """Katmanları (offset_saniye, örnekler) hizalayıp toplar."""
    total = max(int(off * SAMPLE_RATE) + len(s) for off, s in layers)
    out = [0.0] * total
    for off, s in layers:
        base = int(off * SAMPLE_RATE)
        for i, v in enumerate(s):
            out[base + i] += v
    return out


def normalize(samples, peak=0.62):
    m = max(abs(v) for v in samples) or 1.0
    k = peak / m
    return [v * k for v in samples]


def write_wav(path, samples):
    samples = normalize(samples)
    samples += [0.0] * int(SAMPLE_RATE * 0.08)  # sessiz kuyruk
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(v * 32767))))
            for v in samples
        )
        w.writeframes(frames)
    print(f"  ✓ {path} ({os.path.getsize(path) // 1024} KB)")


# Cam çan: inharmonik parsiyeller (oran, genlik, sönüm)
GLASS = [
    (1.00, 1.00, 3.2),
    (2.76, 0.34, 5.0),
    (5.40, 0.14, 7.5),
    (8.93, 0.05, 11.0),
]

# Marimba: tahta çubuk modları — hızlı sönen üst modlar
MARIMBA = [
    (1.00, 1.00, 5.5),
    (3.93, 0.22, 14.0),
    (9.20, 0.07, 22.0),
]


def main():
    out_dir = os.path.join(
        os.path.dirname(__file__), "..", "..",
        "android", "app", "src", "main", "res", "raw",
    )
    out_dir = os.path.normpath(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    print(f"Çıktı dizini: {out_dir}")

    # 1) Kayıtsız numara (Axion Agent) — imza ses: yükselen iki cam nota
    #    A5 → E6 (tam beşli yukarı): net, umut veren "fırsat" hissi.
    capture = mix(
        (0.00, bell_note(880.00, 1.05, GLASS)),
        (0.16, bell_note(1318.51, 1.25, GLASS, brightness=0.85)),
    )
    write_wav(os.path.join(out_dir, "axion_capture_chime.wav"), capture)

    # 2) Görev hatırlatıcı — tek sıcak marimba notası + oktav yankısı.
    #    F5; sakin "vakti geldi" dokunuşu.
    task = mix(
        (0.00, bell_note(698.46, 0.85, MARIMBA)),
        (0.22, bell_note(1396.91, 0.70, MARIMBA, brightness=0.5)),
    )
    write_wav(os.path.join(out_dir, "axion_task_tone.wav"), task)

    # 3) İcra hatırlatıcı — alçalan yumuşak motif G5 → D5.
    #    Nazik, ısrarcı olmayan "unutma" hissi.
    reminder = mix(
        (0.00, bell_note(783.99, 0.95, GLASS, brightness=0.7)),
        (0.20, bell_note(587.33, 1.15, GLASS, brightness=0.6)),
    )
    write_wav(os.path.join(out_dir, "axion_reminder_tone.wav"), reminder)

    print("Tamamlandı — 3 bildirim sesi üretildi.")


if __name__ == "__main__":
    main()
