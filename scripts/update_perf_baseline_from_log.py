#!/usr/bin/env python3
"""[Perf] logundan docs/perf_baseline.md tablolarını günceller."""
from __future__ import annotations

import argparse
import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASELINE = ROOT / "docs" / "perf_baseline.md"

TARGETS = {
    "main_entered": "0",
    "bootstrap_parallel_done": "< 4500",
    "run_app": "< 5000",
    "first_frame": "< 5500",
    "role_shell_interactive": "ağa bağlı",
    "role_shell_resolved": "ağa bağlı",
}


def parse_log(text: str) -> tuple[dict[str, int], list[tuple[str, int, int | None]]]:
    milestones: dict[str, int] = {}
    screens: list[tuple[str, int, int | None]] = []
    for line in text.splitlines():
        m = re.search(
            r"\[Perf\] startup_milestone name=(\S+) elapsed_ms=(\d+)", line
        )
        if m:
            milestones[m.group(1)] = int(m.group(2))
            continue
        s = re.search(
            r"\[Perf\] screen_content_ready screen=(\S+) (\d+)ms(?: items=(\d+))?",
            line,
        )
        if s:
            items = int(s.group(3)) if s.group(3) else None
            screens.append((s.group(1), int(s.group(2)), items))
    return milestones, screens


def md_table(headers: list[str], rows: list[list[str]]) -> str:
    lines = [
        "| " + " | ".join(headers) + " |",
        "|" + "|".join(["---"] * len(headers)) + "|",
    ]
    for row in rows:
        lines.append("| " + " | ".join(row) + " |")
    return "\n".join(lines)


def replace_between(doc: str, start: str, end: str, replacement: str) -> str:
    pattern = re.compile(
        re.escape(start) + r".*?(?=" + re.escape(end) + r")",
        re.DOTALL,
    )
    if not pattern.search(doc):
        return doc
    return pattern.sub(start + replacement, doc, count=1)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("log_file", type=Path)
    p.add_argument("--device", default="macOS (automated)")
    p.add_argument("--role", default="—")
    p.add_argument("--note", default="CAPTURE_STARTUP_PERF otomatik test")
    args = p.parse_args()

    text = args.log_file.read_text(encoding="utf-8", errors="replace")
    milestones, screens = parse_log(text)
    if not milestones:
        print("Uyarı: milestone yok, perf_baseline.md güncellenmedi.")
        return

    today = date.today().isoformat()
    doc = BASELINE.read_text(encoding="utf-8")

    summary_row = (
        f"| {today} | automated test | {args.device} | {args.role} | {args.note} |"
    )
    doc = re.sub(
        r"\| 2026-05-19 \| profile \| macOS \(ölçüm bekleniyor\).*?\|\n",
        summary_row + "\n",
        doc,
        count=1,
    )

    m_rows: list[list[str]] = []
    for name, hint in TARGETS.items():
        ms = milestones.get(name)
        m_rows.append([name, str(ms) if ms is not None else "", hint])
    for name, ms in milestones.items():
        if name not in TARGETS:
            m_rows.append([name, str(ms), ""])

    m_block = md_table(["name", "ms", "Hedef (yönlendirici)"], m_rows) + "\n\n"
    doc = replace_between(
        doc,
        "### Startup milestone (`elapsed_ms` = main()'den itibaren)\n\n",
        "### İlk ekran (`screen_content_ready`)\n\n",
        m_block,
    )

    if screens:
        s_rows = [
            [name, str(ms), str(items) if items is not None else ""]
            for name, ms, items in screens
        ]
        s_block = md_table(["screen", "ms", "items"], s_rows) + "\n\n"
        doc = replace_between(
            doc,
            "### İlk ekran (`screen_content_ready`)\n\n",
            "### Ham log (yapıştırın)\n\n",
            s_block,
        )

    raw = "\n".join(line for line in text.splitlines() if "[Perf]" in line)
    doc = re.sub(
        r"### Ham log \(yapıştırın\)\n\n```text\n.*?\n```",
        "### Ham log (yapıştırın)\n\n```text\n" + raw + "\n```",
        doc,
        count=1,
        flags=re.DOTALL,
    )

    BASELINE.write_text(doc, encoding="utf-8")
    print(f"Güncellendi: {BASELINE}")


if __name__ == "__main__":
    main()
