#!/usr/bin/env python3
"""Executa a suite BRS dos parsers puros do catalogo Saimo."""
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    npx = shutil.which("npx")
    if npx is None:
        print("npx nao encontrado. Instale as dependencias com: npm install", file=sys.stderr)
        return 2

    command = [
        npx,
        "brs",
        "-r",
        ".",
        "SaimoTV/source/bslib.brs",
        "tools/tests/parsers_test.brs",
    ]
    completed = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    output = completed.stdout
    if completed.stderr:
        output = output + completed.stderr
    print(output, end="" if output.endswith("\n") else "\n")

    if completed.returncode != 0:
        print(f"Falha ao executar o brs (codigo {completed.returncode}).", file=sys.stderr)
        return 1
    if "TESTS_FAILED" in output or "TESTS_PASS" not in output:
        print("Os testes de parser nao passaram.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
