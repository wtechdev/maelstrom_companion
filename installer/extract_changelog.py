#!/usr/bin/env python3
"""Estrae le note di release per un tag specifico dal CHANGELOG.md."""

import re
import sys


def estrai_note(tag: str, percorso_changelog: str = "CHANGELOG.md") -> str:
    """Ritorna il corpo della sezione corrispondente al tag dato."""
    contenuto = open(percorso_changelog).read()
    pattern = r"## \[" + re.escape(tag) + r"\][^\n]*\n(.*?)(?=\n## \[|\Z)"
    m = re.search(pattern, contenuto, re.DOTALL)
    return m.group(1).strip() if m else ""


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("Uso: extract_changelog.py <versione>  es: 0.1.0-beta.2")
    print(estrai_note(sys.argv[1]))
