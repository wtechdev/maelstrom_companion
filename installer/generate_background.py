#!/usr/bin/env python3
"""Prepara lo sfondo PNG brandizzato per il DMG di Maelstrom Companion.

Copia e ridimensiona dmg_background_source.png a 1200x800 (@2x per Retina).
"""

import shutil
from pathlib import Path
from PIL import Image

DIR = Path(__file__).parent
SORGENTE = DIR / "dmg_background_source.png"
OUTPUT = DIR / "dmg_background.png"
LARGHEZZA = 1200
ALTEZZA = 800


def main() -> None:
    """Ridimensiona la sorgente e salva l'output pronto per create-dmg."""
    if not SORGENTE.exists():
        raise FileNotFoundError(f"Immagine sorgente non trovata: {SORGENTE}")

    img = Image.open(SORGENTE).convert("RGB")

    if img.size != (LARGHEZZA, ALTEZZA):
        img = img.resize((LARGHEZZA, ALTEZZA), Image.LANCZOS)

    img.save(OUTPUT, "PNG")
    print(f"Sfondo salvato in: {OUTPUT} ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    main()
