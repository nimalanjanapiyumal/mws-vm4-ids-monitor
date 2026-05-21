#!/usr/bin/env python3
"""Simple Suricata fast.log watcher for MWS lab evidence."""

from __future__ import annotations

import os
import time
from pathlib import Path

LOG_FILE = Path(os.environ.get("SURICATA_FAST_LOG", "/var/log/suricata/fast.log"))
KEYWORDS = ("MWS", "MQTT", "unauthorised", "false-normal")


def follow(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.touch(exist_ok=True)
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        handle.seek(0, os.SEEK_END)
        while True:
            line = handle.readline()
            if not line:
                time.sleep(0.5)
                continue
            yield line.rstrip("\n")


def main() -> int:
    print(f"[INFO] Watching IDS log: {LOG_FILE}", flush=True)
    for line in follow(LOG_FILE):
        if any(keyword.lower() in line.lower() for keyword in KEYWORDS):
            print(f"[IDS] {line}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
