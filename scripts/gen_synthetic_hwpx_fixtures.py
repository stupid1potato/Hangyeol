#!/usr/bin/env python3
"""Regenerate synthetic HWPX fixtures F14 / F16 / F21 from COMMIT_OK hub-A.

Derived from fixtures/hub_hwpxlib_SimpleTable.hwpx (Apache-2.0, neolord0/hwpxlib).
Does not invent HWP bytes and does not touch HOLD_LICENSE sources.

  F14  byte-identical copy with a .pdf filename (format detect ignores extension)
  F16  truncated mid-file so the ZIP container is broken
  F21  pretty-printed XML + packaging rule breaks (mimetype not first, deflated)
"""

from __future__ import annotations

import hashlib
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "fixtures"
HUB_A = FIXTURES / "hub_hwpxlib_SimpleTable.hwpx"

F14 = FIXTURES / "14_wrong_ext_hwpx.pdf"
F16 = FIXTURES / "16_corrupt_truncated.hwpx"
F21 = FIXTURES / "21_prettyprinted_bad.hwpx"

# Mid-file truncate: keep first N bytes (ZIP EOCD / later entries are gone).
F16_KEEP_BYTES = 1024


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pretty_xml(data: bytes) -> bytes:
    """Indent XML. Prefer xmllint; fall back to minidom."""
    try:
        proc = subprocess.run(
            ["xmllint", "--format", "-"],
            input=data,
            capture_output=True,
            check=False,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            return proc.stdout
    except FileNotFoundError:
        pass

    from xml.dom.minidom import parseString

    parsed = parseString(data)
    return parsed.toprettyxml(indent="  ", encoding="UTF-8")


def write_f14() -> None:
    shutil.copyfile(HUB_A, F14)


def write_f16() -> None:
    data = HUB_A.read_bytes()
    if len(data) <= F16_KEEP_BYTES:
        raise SystemExit(
            f"{HUB_A.name} is only {len(data)} bytes; need > {F16_KEEP_BYTES} to truncate"
        )
    F16.write_bytes(data[:F16_KEEP_BYTES])


def write_f21() -> None:
    entries: list[tuple[str, bytes]] = []
    with zipfile.ZipFile(HUB_A) as zin:
        for info in zin.infolist():
            if info.is_dir():
                continue
            payload = zin.read(info.filename)
            if info.filename.endswith(".xml"):
                payload = pretty_xml(payload)
            entries.append((info.filename, payload))

    # Break OPC/HWPX packaging: mimetype must be first and STORED.
    # Put mimetype last and DEFLATE every member, including mimetype.
    entries.sort(key=lambda item: item[0] == "mimetype")

    if F21.exists():
        F21.unlink()
    with zipfile.ZipFile(F21, "w") as zout:
        for name, payload in entries:
            zout.writestr(name, payload, compress_type=zipfile.ZIP_DEFLATED)


def main() -> int:
    if not HUB_A.is_file():
        print(f"missing hub-A: {HUB_A}", file=sys.stderr)
        return 1

    write_f14()
    write_f16()
    write_f21()

    print(f"base  {HUB_A.name}  {HUB_A.stat().st_size}  {sha256(HUB_A)}")
    for path in (F14, F16, F21):
        print(f"wrote {path.name}  {path.stat().st_size}  {sha256(path)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
