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
    return '''#!/bin/bash
DMG_PATH="\${MAELSTROM_DMG_PATH}"
APP_DEST="\${MAELSTROM_APP_DEST}"

sleep 2

MOUNT=\$(hdiutil attach "\$DMG_PATH" -nobrowse -quiet | tail -1 | awk '{print \$NF}')

rm -rf "\$APP_DEST"
ditto "\$MOUNT/Maelstrom Companion.app" "\$APP_DEST"

hdiutil detach "\$MOUNT" -quiet
open "\$APP_DEST"

rm -f "\$DMG_PATH"
rm -f "\$0"
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
