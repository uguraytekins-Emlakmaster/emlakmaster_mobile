#!/usr/bin/env python3
"""[Perf] logunu scripts/perf_thresholds.json ile doğrular; CI regresyon."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
THRESHOLDS = ROOT / "scripts" / "perf_thresholds.json"


def parse_log(text: str) -> tuple[dict[str, int], dict[str, int]]:
    milestones: dict[str, int] = {}
    screens: dict[str, int] = {}
    for line in text.splitlines():
        m = re.search(
            r"\[Perf\] startup_milestone name=(\S+) elapsed_ms=(\d+)", line
        )
        if m:
            milestones[m.group(1)] = int(m.group(2))
            continue
        s = re.search(
            r"\[Perf\] screen_content_ready screen=(\S+) (\d+)ms", line
        )
        if s:
            screens[s.group(1)] = int(s.group(2))
    return milestones, screens


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("log_file", type=Path)
    p.add_argument(
        "--mode",
        choices=("automated", "profile"),
        default="automated",
    )
    p.add_argument(
        "--thresholds",
        type=Path,
        default=THRESHOLDS,
    )
    args = p.parse_args()

    cfg = json.loads(args.thresholds.read_text(encoding="utf-8"))[args.mode]
    text = args.log_file.read_text(encoding="utf-8", errors="replace")
    milestones, screens = parse_log(text)

    errors: list[str] = []
    warnings: list[str] = []

    for name in cfg.get("required_milestones", []):
        if name not in milestones:
            errors.append(f"eksik milestone: {name}")

    for name, limit in cfg.get("limits_ms", {}).items():
        if name not in milestones:
            continue
        ms = milestones[name]
        if ms > limit:
            errors.append(f"{name}: {ms}ms > limit {limit}ms")

    for name, limit in cfg.get("screen_limits_ms", {}).items():
        if name not in screens:
            warnings.append(f"eksik screen_content_ready: {name} (giriş/dashboard?)")
            continue
        ms = screens[name]
        if ms > limit:
            errors.append(f"screen {name}: {ms}ms > limit {limit}ms")

    for name, target in cfg.get("screen_targets_ms", {}).items():
        if name not in screens:
            continue
        ms = screens[name]
        if ms > target:
            warnings.append(
                f"screen {name}: {ms}ms > hedef {target}ms (profile iyileştirme)"
            )

    for name in cfg.get("optional_milestones", []):
        if name not in milestones:
            warnings.append(f"opsiyonel milestone yok: {name}")

    if not milestones:
        errors.append("logda [Perf] startup_milestone yok")

    print(f"=== Perf eşik kontrolü ({args.mode}) ===")
    print(f"Log: {args.log_file}")
    for name, ms in sorted(milestones.items()):
        limit = cfg.get("limits_ms", {}).get(name)
        suffix = f" (limit {limit}ms)" if limit is not None else ""
        print(f"  {name}: {ms}ms{suffix}")
    for name, ms in sorted(screens.items()):
        print(f"  screen {name}: {ms}ms")

    for w in warnings:
        print(f"UYARI: {w}", file=sys.stderr)

    if errors:
        print("HATA:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print("OK: tüm zorunlu eşikler geçildi.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
