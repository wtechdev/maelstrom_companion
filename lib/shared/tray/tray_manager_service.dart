import 'package:flutter/painting.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayManagerService {
  static Future<void> init() async {
    await trayManager.setIcon('assets/images/tray_icon.png');
    await trayManager.setContextMenu(_buildMenu());
  }

  static Menu _buildMenu() => Menu(items: [
        MenuItem(key: 'toggle', label: 'Apri / Chiudi'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Esci'),
      ]);

  static Future<void> aggiornaTitolo(String? testo) async {
    await trayManager.setTitle(testo ?? '');
  }

  static Future<void> gestisciClick() async {
    final visible = await windowManager.isVisible();
    if (visible) {
      await windowManager.hide();
    } else {
      await _posizionaVicinoTray();
      await windowManager.show();
      await windowManager.focus();
    }
  }

  /// Posiziona la finestra appena sotto l'icona tray, allineata a destra.
  static Future<void> _posizionaVicinoTray() async {
    try {
      final trayBounds = await trayManager.getBounds();
      if (trayBounds == null) return;
      final winSize = await windowManager.getSize();
      final x = trayBounds.right - winSize.width;
      final y = trayBounds.bottom + 4;
      await windowManager.setPosition(Offset(x, y));
    } catch (_) {
      // Se fallisce, la finestra appare dove si trova
    }
  }

  static Future<void> gestisciMenuClick(String key) async {
    switch (key) {
      case 'toggle':
        await gestisciClick();
      case 'quit':
        await windowManager.close();
    }
  }
}
