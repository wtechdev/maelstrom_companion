import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../app_router.dart';

class TrayManagerService {
  static Future<void> init() async {
    await trayManager.setIcon('assets/images/tray_icon.png');
    await trayManager.setContextMenu(_buildMenu());
  }

  static Menu _buildMenu() => Menu(items: [
        MenuItem(key: 'projects', label: 'Progetti'),
        MenuItem(key: 'timer', label: 'Registra'),
        MenuItem(key: 'today', label: 'Oggi'),
        MenuItem(key: 'week', label: 'Settimana'),
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
      case 'projects':
        await _mostraENaviga('/home/projects');
      case 'timer':
        await _mostraENaviga('/home/timer');
      case 'today':
        await _mostraENaviga('/home/today');
      case 'week':
        await _mostraENaviga('/home/week');
      case 'quit':
        exit(0);
    }
  }

  /// Mostra la finestra (se nascosta) e naviga alla route indicata.
  static Future<void> _mostraENaviga(String route) async {
    final visible = await windowManager.isVisible();
    if (!visible) {
      await _posizionaVicinoTray();
      await windowManager.show();
      await windowManager.focus();
    }
    routerInstance?.go(route);
  }
}
