#!/usr/bin/env python3
"""HapticFeedback.* çağrılarını AppFeedback.* ile değiştirir."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"
IMPORT = "import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';\n"
SKIP = {
    ROOT / "core" / "feedback" / "app_feedback.dart",
}

REPLACEMENTS = [
    ("HapticFeedback.lightImpact()", "AppFeedback.lightImpact()"),
    ("HapticFeedback.mediumImpact()", "AppFeedback.mediumImpact()"),
    ("HapticFeedback.heavyImpact()", "AppFeedback.heavyImpact()"),
    ("HapticFeedback.selectionClick()", "AppFeedback.selectionClick()"),
    ("HapticFeedback.vibrate()", "AppFeedback.vibrate()"),
    ("await HapticFeedback.lightImpact()", "await AppFeedback.lightImpact()"),
    ("await HapticFeedback.mediumImpact()", "await AppFeedback.mediumImpact()"),
    ("await HapticFeedback.heavyImpact()", "await AppFeedback.heavyImpact()"),
    ("await HapticFeedback.selectionClick()", "await AppFeedback.selectionClick()"),
    ("await HapticFeedback.vibrate()", "await AppFeedback.vibrate()"),
]


def migrate_file(path: Path) -> bool:
    if path in SKIP:
        return False
    text = path.read_text(encoding="utf-8")
    if "HapticFeedback" not in text:
        return False
    original = text
    for old, new in REPLACEMENTS:
        text = text.replace(old, new)
    if "app_feedback.dart" not in text:
        lines = text.splitlines(keepends=True)
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                insert_at = i + 1
            elif insert_at > 0 and not line.startswith("import "):
                break
        lines.insert(insert_at, IMPORT)
        text = "".join(lines)
    # HapticFeedback import artık gerekmiyorsa services import'tan kaldır (basit)
    if path.write_text(text, encoding="utf-8") != len(original):
        pass
    return text != original


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        if migrate_file(path):
            print(f"updated {path.relative_to(ROOT.parent)}")
            changed += 1
    print(f"done: {changed} files")


if __name__ == "__main__":
    main()
