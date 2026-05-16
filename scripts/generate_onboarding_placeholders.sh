#!/usr/bin/env bash
# Geçici 4×4 PNG üretir (yalnızca asset yolu doğrulaması için).
# Gerçek tanıtım ekran görüntülerini assets/onboarding/ altına manuel koyun.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/onboarding"
mkdir -p "$OUT"
OUT="$OUT" python3 - <<'PY'
import os
import struct
import zlib
from pathlib import Path

def png_rgb(w, h, rgb=(0xD8, 0xE4, 0xF0)):
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
    raw = b''.join(b'\x00' + bytes(rgb) * w for _ in range(h))
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')

out = Path(os.environ['OUT'])
names = [
    'manager_command.png', 'consultant_gunum.png', 'smart_calls.png',
    'market_listings.png', 'office_messages.png',
]
for name in names:
    p = out / name
    p.write_bytes(png_rgb(4, 4))
    print('wrote', p)
PY
