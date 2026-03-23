import 'package:flutter_test/flutter_test.dart';
import 'package:maelstrom_companion/core/models/user_profile.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('parsing corretto con tutti i campi', () {
      final json = {
        'data': {
          'uid': 'abc123',
          'nome': 'Mario',
          'cognome': 'Rossi',
          'email': 'mario@demo.local',
          'ruolo': 'dipendente',
          'struttura': {'id': 1, 'nome': 'Azienda Demo A'},
        }
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.nome, 'Mario');
      expect(profile.cognome, 'Rossi');
      expect(profile.email, 'mario@demo.local');
      expect(profile.ruolo, 'dipendente');
      expect(profile.struttura, 'Azienda Demo A');
    });

    test('struttura null se assente', () {
      final json = {
        'data': {
          'uid': 'abc123',
          'nome': 'Mario',
          'cognome': 'Rossi',
          'email': 'mario@demo.local',
          'ruolo': 'dipendente',
          'struttura': null,
        }
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.struttura, isNull);
    });

    test('nomeCompleto concatena nome e cognome', () {
      const profile = UserProfile(
        nome: 'Mario',
        cognome: 'Rossi',
        email: 'mario@demo.local',
      );
      expect(profile.nomeCompleto, 'Mario Rossi');
    });
  });
}
