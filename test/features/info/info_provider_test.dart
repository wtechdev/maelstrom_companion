import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:maelstrom_companion/core/api/api_client.dart';
import 'package:maelstrom_companion/core/auth/auth_provider.dart';
import 'package:maelstrom_companion/features/info/info_provider.dart';

// Mock per ApiClient
class MockApiClient extends Mock implements ApiClient {}

// Mock per http.Client
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('InfoNotifier', () {
    test('stato iniziale è idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Override del FutureProvider con un valore sincrono null
      final containerOverride = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(containerOverride.dispose);

      expect(containerOverride.read(infoProvider).updateStatus, UpdateStatus.idle);
    });

    test('aggiornaProgress aggiorna downloadProgress', () {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      container.read(infoProvider.notifier).aggiornaProgress(0.5);
      expect(container.read(infoProvider).downloadProgress, 0.5);
    });

    test('impostaErrore cambia stato in error', () {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      container.read(infoProvider.notifier).impostaErrore('errore test');
      final state = container.read(infoProvider);
      expect(state.updateStatus, UpdateStatus.error);
      expect(state.errore, 'errore test');
    });
  });
}
