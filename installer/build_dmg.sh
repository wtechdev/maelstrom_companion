#!/bin/bash
# Script locale per creare il DMG di Maelstrom Companion.
# Prerequisiti: brew install create-dmg, pip install Pillow
set -e

cd "$(dirname "$0")/.."

VERSION=$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)
DMG_NAME="Maelstrom-Companion-${VERSION}.dmg"
APP_PATH="build/macos/Build/Products/Release/maelstrom_companion.app"

echo "Versione: ${VERSION}"
echo "DMG: ${DMG_NAME}"

# Build Flutter release
flutter build macos --release

# Genera sfondo brandizzato
python3 installer/generate_background.py

# Rimuovi DMG precedente se esiste
rm -f "${DMG_NAME}"

# Crea DMG
create-dmg \
  --volname "Maelstrom Companion" \
  --background "installer/dmg_background.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 128 \
  --icon "maelstrom_companion.app" 150 190 \
  --app-drop-link 450 190 \
  "${DMG_NAME}" \
  "${APP_PATH}"

echo "DMG creato: ${DMG_NAME}"
