import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maelstrom_companion/core/auth/token_storage.dart';

void main() {
  late Directory tmpDir;
  late TokenStorage storage;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('token_storage_test_');
    storage = TokenStorage(dirOverride: tmpDir.path);
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  group('salva e leggi', () {
    test('salva url, token e versione nel file JSON', () async {
      await storage.salva(url: 'https://example.com', token: 'tok123', versione: '1.2.0');

      final raw = await File('${tmpDir.path}/maelstrom_credentials.json').readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;

      expect(map['url'], 'https://example.com');
      expect(map['token'], 'tok123');
      expect(map['versione'], '1.2.0');
    });

    test('getVersione restituisce la versione salvata', () async {
      await storage.salva(url: 'https://example.com', token: 'tok', versione: '2.0.0');
      expect(await storage.getVersione(), '2.0.0');
    });

    test('getVersione restituisce null se il file non esiste', () async {
      expect(await storage.getVersione(), isNull);
    });
  });

  group('cancellaSeMismatchVersione', () {
    test('non cancella nulla se versione corrisponde', () async {
      await storage.salva(url: 'https://example.com', token: 'tok', versione: '1.1.4');
      await storage.cancellaSeMismatchVersione('1.1.4');
      expect(await storage.haCredenziali(), isTrue);
    });

    test('cancella le credenziali se versione è diversa', () async {
      await storage.salva(url: 'https://example.com', token: 'tok', versione: '1.1.3');
      await storage.cancellaSeMismatchVersione('1.1.4');
      expect(await storage.haCredenziali(), isFalse);
    });

    test('non fa nulla se non ci sono credenziali salvate', () async {
      await expectLater(
        storage.cancellaSeMismatchVersione('1.1.4'),
        completes,
      );
    });

    test('non cancella se versione salvata è null (file vecchio senza campo versione)', () async {
      // Simula un file di credenziali precedente al versioning
      await File('${tmpDir.path}/maelstrom_credentials.json').writeAsString(
        jsonEncode({'url': 'https://example.com', 'token': 'tok'}),
      );
      await storage.cancellaSeMismatchVersione('1.1.4');
      // Le credenziali rimangono — retrocompatibilità con sessioni pre-versioning
      expect(await storage.haCredenziali(), isTrue);
    });
  });
}
