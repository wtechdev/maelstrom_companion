import 'dart:io';
import 'package:http/http.dart' as http;

/// Servizio per il download del DMG e l'esecuzione dello script di aggiornamento.
class UpdateService {
  /// Path del DMG da scaricare per la versione specificata.
  static String dmgPath(String version) =>
      '/tmp/MaelstromCompanion-$version.dmg';

  /// Path dell'app installata corrente (deriva da Platform.resolvedExecutable).
  /// Risale di 3 livelli dall'eseguibile per ottenere il bundle .app:
  /// es. ".../Maelstrom Companion.app/Contents/MacOS/binary" → ".../Maelstrom Companion.app"
  static String get appInstallPath {
    final exe = Platform.resolvedExecutable;
    final parts = exe.split('/');
    if (parts.length > 3) {
      return parts.sublist(0, parts.length - 3).join('/');
    }
    return '/Applications/Maelstrom Companion.app';
  }

  /// Genera il contenuto dello script bash di aggiornamento.
  /// I path vengono passati come variabili di ambiente, non interpolati inline.
  static String generaScript() {
    return r'''#!/bin/bash
LOG="/tmp/maelstrom_updater.log"
exec > "$LOG" 2>&1
set -xe

DMG_PATH="${MAELSTROM_DMG_PATH}"
APP_DEST="${MAELSTROM_APP_DEST}"
MOUNT_POINT="/tmp/maelstrom_mount_$$"
TEMP_APP="/tmp/MaelstromCompanion_new_$$.app"

echo "=== Maelstrom Updater avviato ==="
echo "DMG:  $DMG_PATH"
echo "DEST: $APP_DEST"

sleep 2

mkdir -p "$MOUNT_POINT"
hdiutil attach "$DMG_PATH" -nobrowse -quiet -mountpoint "$MOUNT_POINT"
echo "Contenuto DMG:"
ls "$MOUNT_POINT"

# Copia in posizione temporanea — se fallisce l'app originale è ancora intatta
ditto "$MOUNT_POINT/Maelstrom Companion.app" "$TEMP_APP"

# Verifica che la copia contenga l'eseguibile
if [ ! -f "$TEMP_APP/Contents/MacOS/Maelstrom Companion" ]; then
  echo "ERRORE: bundle copiato non valido"
  rm -rf "$TEMP_APP"
  hdiutil detach "$MOUNT_POINT" -force -quiet
  exit 1
fi
echo "Bundle verificato OK"

# Ora è sicuro rimuovere la vecchia versione e spostare quella nuova
rm -rf "$APP_DEST"
mv "$TEMP_APP" "$APP_DEST"

hdiutil detach "$MOUNT_POINT" -force -quiet
rm -rf "$MOUNT_POINT"

echo "Lancio app: $APP_DEST"
open "$APP_DEST"

rm -f "$DMG_PATH"
rm -f "$0"
echo "=== Fine ==="
''';
  }

  /// Scarica il DMG dall'URL specificato, chiamando [onProgress] con avanzamento 0.0–1.0.
  Future<void> scaricaDmg({
    required String url,
    required String destinazione,
    required void Function(double) onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download fallito: HTTP ${response.statusCode}');
      }

      final file = File(destinazione);
      final sink = file.openWrite();
      final total = response.contentLength ?? 0;
      var received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress(received / total);
        }
      }

      await sink.close();
    } finally {
      client.close();
    }
  }

  /// [DEBUG] Testa l'aggiornamento direttamente da un DMG locale, senza download.
  Future<void> testAggiornamentoDmgLocale({
    required String dmgPath,
    required String appPath,
  }) => avviaAggiornamento(dmgPath: dmgPath, appPath: appPath);

  /// Scrive lo script bash in /tmp e lo avvia con le variabili di ambiente.
  Future<void> avviaAggiornamento({
    required String dmgPath,
    required String appPath,
  }) async {
    const scriptPath = '/tmp/maelstrom_updater.sh';
    final scriptFile = File(scriptPath);
    await scriptFile.writeAsString(generaScript());

    await Process.run('chmod', ['+x', scriptPath]);

    await Process.start(
      scriptPath,
      [],
      runInShell: false,
      environment: {
        'MAELSTROM_DMG_PATH': dmgPath,
        'MAELSTROM_APP_DEST': appPath,
      },
    );
  }
}
