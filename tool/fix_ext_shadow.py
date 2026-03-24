#!/usr/bin/env python3
"""Replace AppThemeExtension.of(context) with ext when line is not the ext definition."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

EXT_DEF = re.compile(r"^\s*final\s+ext\s*=\s*AppThemeExtension\.of\(context\)")


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "final ext = AppThemeExtension.of(context)" not in text:
        return False
    if "AppThemeExtension.of(context)" not in text:
        return False
    lines = text.splitlines(keepends=True)
    out = []
    changed = False
    for line in lines:
        if EXT_DEF.match(line.split("//")[0]):
            out.append(line)
            continue
        new_line = line.replace("AppThemeExtension.of(context)", "ext")
        if new_line != line:
            changed = True
        out.append(new_line)
    if not changed:
        return False
    path.write_text("".join(out), encoding="utf-8")
    return True


def main() -> None:
    base = ROOT.parent
    paths = [Path(p) for p in sys.argv[1:]] if len(sys.argv) > 1 else sorted(ROOT.rglob("*.dart"))
    n = 0
    for p in paths:
        p = p if p.is_absolute() else base / p
        if not p.exists():
            continue
        if process_file(p):
            print(p.relative_to(base))
            n += 1
    print(f"updated {n} files")


if __name__ == "__main__":
    main()
