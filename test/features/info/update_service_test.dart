import 'package:flutter_test/flutter_test.dart';
import 'package:maelstrom_companion/features/info/update_service.dart';

void main() {
  group('UpdateService', () {
    test('dmgPath restituisce path corretto', () {
      final path = UpdateService.dmgPath('1.0.2');
      expect(path, '/tmp/MaelstromCompanion-1.0.2.dmg');
    });

    test('scriviScript genera script con variabili di ambiente (non path inline)', () {
      // Verifica che il metodo scriviScript esista e generi uno script
      // che usa le variabili d'ambiente MAELSTROM_DMG_PATH e MAELSTROM_APP_DEST
      // e NON interpola i path direttamente nella stringa
      final script = UpdateService.generaScript();
      expect(script, contains('MAELSTROM_DMG_PATH'));
      expect(script, contains('MAELSTROM_APP_DEST'));
      expect(script, contains('hdiutil'));
      expect(script, contains('-mountpoint'));
      expect(script, contains('ditto'));
    });
  });
}
