import 'package:flutter_test/flutter_test.dart';
import 'package:maelstrom_companion/core/utils/version_utils.dart';

void main() {
  group('isNewerVersion', () {
    test('true se latest è maggiore di installed (patch)', () {
      expect(isNewerVersion('1.0.1', '1.0.2'), isTrue);
    });

    test('false se versioni uguali', () {
      expect(isNewerVersion('1.0.1', '1.0.1'), isFalse);
    });

    test('false se latest è minore', () {
      expect(isNewerVersion('1.0.1', '1.0.0'), isFalse);
    });

    test('false se latest è pre-release', () {
      expect(isNewerVersion('1.0.1', '1.1.0-beta'), isFalse);
    });

    test('true con confronto numerico (non lessicografico)', () {
      expect(isNewerVersion('1.0.9', '1.0.10'), isTrue);
    });

    test('true se minor è maggiore', () {
      expect(isNewerVersion('1.0.1', '1.1.0'), isTrue);
    });

    test('true se major è maggiore', () {
      expect(isNewerVersion('1.9.9', '2.0.0'), isTrue);
    });
  });
}
