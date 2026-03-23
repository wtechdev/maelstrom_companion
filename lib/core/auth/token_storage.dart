import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Salva le credenziali su file JSON in Application Support.
/// Evita il Keychain (che richiede code signing) durante lo sviluppo.
class TokenStorage {
  static const _fileName = 'maelstrom_credentials.json';

  /// Percorso directory opzionale — usato solo nei test per isolare il filesystem.
  @visibleForTesting
  final String? dirOverride;

  const TokenStorage({this.dirOverride});

  Future<File> _file() async {
    final dirPath = dirOverride ?? (await getApplicationSupportDirectory()).path;
    return File('$dirPath/$_fileName');
  }

  Future<Map<String, String>> _leggi() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return {};
      final raw = await f.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (e) {
      debugPrint('TokenStorage._leggi error: $e');
      return {};
    }
  }

  Future<void> _scrivi(Map<String, String> data) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(data));
  }

  Future<String?> getUrl() async => (await _leggi())['url'];
  Future<String?> getToken() async => (await _leggi())['token'];
  Future<String?> getVersione() async => (await _leggi())['versione'];

  Future<void> salva({
    required String url,
    required String token,
    required String versione,
  }) async {
    await _scrivi({
      'url': url.trimRight().replaceAll(RegExp(r'/$'), ''),
      'token': token.trim(),
      'versione': versione,
    });
  }

  /// Cancella le credenziali se la versione memorizzata è diversa da [versioneCorrente].
  /// Chiamare all'avvio prima di verificare le credenziali.
  Future<void> cancellaSeMismatchVersione(String versioneCorrente) async {
    final versioneSalvata = await getVersione();
    if (versioneSalvata != null && versioneSalvata != versioneCorrente) {
      debugPrint(
        'TokenStorage: versione cambiata ($versioneSalvata → $versioneCorrente), sessione invalidata.',
      );
      await cancella();
    }
  }

  Future<bool> haCredenziali() async {
    final d = await _leggi();
    return (d['url']?.isNotEmpty ?? false) && (d['token']?.isNotEmpty ?? false);
  }

  Future<void> cancella() async {
    final f = await _file();
    if (f.existsSync()) await f.delete();
  }
}
