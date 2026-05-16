#!/usr/bin/env python3
"""Üretilmiş kısa bildirim / geri bildirim sesleri (WAV, 44.1kHz mono)."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"
SAMPLE_RATE = 44100


def _write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            wf.writeframes(struct.pack("<h", int(clamped * 32767)))


def _tone(freq: float, t: float, duration: float, attack: float = 0.02, decay: float = 0.25) -> float:
    if t < 0 or t > duration:
        return 0.0
    env = min(1.0, t / attack) * math.exp(-3.5 * max(0.0, (t - attack) / decay))
    return math.sin(2 * math.pi * freq * t) * env


def _mix(durations: list[tuple[float, float, float]]) -> list[float]:
    total = max(d[2] for d in durations) + 0.05
    n = int(total * SAMPLE_RATE)
    buf = [0.0] * n
    for freq, start, dur in durations:
        for i in range(n):
            t = i / SAMPLE_RATE - start
            buf[i] += _tone(freq, t, dur)
    peak = max(abs(x) for x in buf) or 1.0
    scale = 0.82 / peak
    return [x * scale for x in buf]


def main() -> None:
    sounds = {
        "notification_chime.wav": _mix([(523.25, 0.0, 0.35), (659.25, 0.12, 0.4)]),
        "notification_sparkle.wav": _mix(
            [(523.25, 0.0, 0.18), (659.25, 0.08, 0.18), (783.99, 0.16, 0.22), (1046.5, 0.24, 0.28)]
        ),
        "notification_bell.wav": _mix([(880.0, 0.0, 0.55), (1760.0, 0.0, 0.35)]),
        "success.wav": _mix([(523.25, 0.0, 0.2), (659.25, 0.1, 0.22), (783.99, 0.2, 0.35)]),
        "error.wav": _mix([(349.23, 0.0, 0.28), (293.66, 0.14, 0.32)]),
        "warning.wav": _mix([(440.0, 0.0, 0.12), (440.0, 0.18, 0.12)]),
        "tap.wav": _mix([(1200.0, 0.0, 0.05)]),
        "message.wav": _mix([(698.46, 0.0, 0.25), (880.0, 0.1, 0.3)]),
    }
    for name, samples in sounds.items():
        _write_wav(OUT / name, samples)
        print(f"wrote {OUT / name}")


if __name__ == "__main__":
    main()
