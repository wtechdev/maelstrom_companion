import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maelstrom_companion/core/models/user_profile.dart';
import 'package:maelstrom_companion/features/info/info_provider.dart';
import 'package:maelstrom_companion/features/info/info_screen.dart';

Widget _buildTestApp(InfoState state) {
  return ProviderScope(
    overrides: [
      infoProvider.overrideWith((ref) => InfoNotifier.withState(state)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: InfoScreen()),
    ),
  );
}

void main() {
  testWidgets('mostra badge Aggiornato con stato upToDate', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      const InfoState(updateStatus: UpdateStatus.upToDate, versione: '1.0.1'),
    ));
    expect(find.textContaining('Aggiornato'), findsOneWidget);
  });

  testWidgets('mostra spinner con stato checking', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      const InfoState(updateStatus: UpdateStatus.checking),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('mostra card aggiornamento con stato updateAvailable', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      const InfoState(
        updateStatus: UpdateStatus.updateAvailable,
        versione: '1.0.1',
        nuovaVersione: '1.0.2',
        dmgUrl: 'https://example.com/app.dmg',
      ),
    ));
    expect(find.textContaining('1.0.2'), findsOneWidget);
    expect(find.text('Aggiorna'), findsOneWidget);
  });

  testWidgets('mostra progress bar con stato downloading', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      const InfoState(
        updateStatus: UpdateStatus.downloading,
        downloadProgress: 0.42,
      ),
    ));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('automaticamente'), findsOneWidget);
  });

  testWidgets('mostra card errore con link Riprova', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      const InfoState(
        updateStatus: UpdateStatus.error,
        errore: 'Impossibile controllare aggiornamenti',
      ),
    ));
    expect(find.textContaining('Impossibile'), findsOneWidget);
    expect(find.text('Riprova'), findsOneWidget);
  });

  testWidgets('mostra dati profilo quando disponibili', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      const InfoState(
        updateStatus: UpdateStatus.upToDate,
        versione: '1.0.1',
        profilo: UserProfile(
          nome: 'Mario',
          cognome: 'Rossi',
          email: 'mario@demo.local',
          ruolo: 'dipendente',
          struttura: 'Azienda Demo A',
        ),
        serverUrl: 'http://localhost:8080',
      ),
    ));
    expect(find.text('Mario Rossi'), findsOneWidget);
    expect(find.text('mario@demo.local'), findsOneWidget);
    expect(find.textContaining('dipendente'), findsOneWidget);
    expect(find.text('http://localhost:8080'), findsOneWidget);
  });
}
