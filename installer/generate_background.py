#!/usr/bin/env python3
"""Genera lo sfondo PNG brandizzato per il DMG di Maelstrom Companion."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

LARGHEZZA = 1200
ALTEZZA = 800
COLORE_SFONDO_TOP = (18, 18, 30)       # blu scuro Maelstrom
COLORE_SFONDO_BOTTOM = (30, 30, 50)    # blu scuro leggermente più chiaro
COLORE_TESTO_TITOLO = (220, 220, 255)  # bianco-lavanda
COLORE_TESTO_ISTRUZIONE = (150, 150, 180)  # grigio-lavanda
OUTPUT_PATH = Path(__file__).parent / "dmg_background.png"


def crea_gradiente(draw: ImageDraw.ImageDraw) -> None:
    """Disegna un gradiente verticale come sfondo."""
    for y in range(ALTEZZA):
        t = y / ALTEZZA
        r = int(COLORE_SFONDO_TOP[0] + t * (COLORE_SFONDO_BOTTOM[0] - COLORE_SFONDO_TOP[0]))
        g = int(COLORE_SFONDO_TOP[1] + t * (COLORE_SFONDO_BOTTOM[1] - COLORE_SFONDO_TOP[1]))
        b = int(COLORE_SFONDO_TOP[2] + t * (COLORE_SFONDO_BOTTOM[2] - COLORE_SFONDO_TOP[2]))
        draw.line([(0, y), (LARGHEZZA, y)], fill=(r, g, b))


def centra_testo(
    draw: ImageDraw.ImageDraw,
    testo: str,
    y: int,
    font: ImageFont.FreeTypeFont | ImageFont.ImageFont,
    colore: tuple[int, int, int],
) -> None:
    """Disegna testo centrato orizzontalmente a una data posizione verticale."""
    bbox = draw.textbbox((0, 0), testo, font=font)
    larghezza_testo = bbox[2] - bbox[0]
    x = (LARGHEZZA - larghezza_testo) // 2
    draw.text((x, y), testo, font=font, fill=colore)


def main() -> None:
    img = Image.new("RGB", (LARGHEZZA, ALTEZZA))
    draw = ImageDraw.Draw(img)

    crea_gradiente(draw)

    # Tenta di usare un font di sistema macOS, fallback su default PIL
    try:
        font_titolo = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 64)
        font_istruzione = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
    except OSError:
        font_titolo = ImageFont.load_default()
        font_istruzione = ImageFont.load_default()

    centra_testo(draw, "Maelstrom Companion", y=120, font=font_titolo, colore=COLORE_TESTO_TITOLO)
    centra_testo(
        draw,
        "Trascina l'app nella cartella Applications",
        y=700,
        font=font_istruzione,
        colore=COLORE_TESTO_ISTRUZIONE,
    )

    img.save(OUTPUT_PATH, "PNG")
    print(f"Sfondo salvato in: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
