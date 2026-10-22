#!/usr/bin/env python3
"""Empacota o canal Roku para sideload."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "SaimoTV"
DIST = ROOT / "dist"
ZIP = DIST / "SaimoTV-roku.zip"
SHA = DIST / "SaimoTV-roku.zip.sha256"


def version():
    manifest = (APP / "manifest").read_text(encoding="utf-8")
    fields = {}
    for line in manifest.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            fields[key.strip()] = value.strip()
    return f"{fields.get('major_version', '0')}.{fields.get('minor_version', '0')}.{fields.get('build_version', '0')}"


def main():
    required = ["manifest", "source/main.brs", "components/MainScene.xml", "components/MainScene.brs"]
    for rel in required:
        if not (APP / rel).exists():
            raise SystemExit(f"Arquivo obrigatorio ausente: {rel}")

    DIST.mkdir(parents=True, exist_ok=True)
    files = sorted(path for path in APP.rglob("*")
                   if path.is_file() and not path.name.lower().endswith(".md"))
    with zipfile.ZipFile(ZIP, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            archive.write(path, path.relative_to(APP).as_posix())
    digest = hashlib.sha256(ZIP.read_bytes()).hexdigest()
    SHA.write_text(digest + "\n", encoding="utf-8")
    print(json.dumps({
        "version": version(),
        "files": len(files),
        "zip": str(ZIP),
        "sha256": digest,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
