# Tray Manager — Icona Menubar macOS

## Panoramica

`TrayManagerService` gestisce l'icona nella menubar macOS, il menu contestuale, il toggle visibilità della finestra e l'aggiornamento del titolo tray quando il timer è attivo. L'integrazione con il ciclo di vita dell'app avviene tramite i mixin `TrayListener` e `WindowListener` in `main.dart`.

---

## File coinvolti

| File | Responsabilità |
|------|---------------|
| `lib/shared/tray/tray_manager_service.dart` | Logica tray: init, click, menu, titolo, posizionamento |
| `lib/main.dart` | Mixin `TrayListener` + `WindowListener` |

---

## TrayManagerService

**Path**: `lib/shared/tray/tray_manager_service.dart`

Classe con soli metodi statici — non istanziabile.

### init()

Chiamato in `main.dart` durante l'inizializzazione:

```dart
static Future<void> init() async {
  await trayManager.setIcon('assets/images/tray_icon.png');
  await trayManager.setContextMenu(_buildMenu());
}
```

L'icona è `brandmark-w-tech_w.png` (variante bianca/monocromatica per la menubar macOS).

### _buildMenu()

```dart
Menu con:
  - MenuItem(key: 'toggle', label: 'Apri / Chiudi')
  - MenuItemSeparator
  - MenuItem(key: 'quit',   label: 'Esci')
```

### aggiornaTitolo(testo?)

Chiamato dal `TimerNotifier` ogni secondo quando il timer è attivo:

```dart
static Future<void> aggiornaTitolo(String? testo) async {
  await trayManager.setTitle(testo ?? '');
}
```

Quando il timer è attivo: `'● 01:23:45'`
Quando inattivo: `''` (nessun testo, solo icona)

### gestisciClick()

Chiamato al click sull'icona tray (`onTrayIconMouseDown`):

```dart
static Future<void> gestisciClick() async {
  final isVisible = await windowManager.isVisible();
  if (isVisible) {
    await windowManager.hide();
  } else {
    await _posizionaVicinoTray();
    await windowManager.show();
    await windowManager.focus();
  }
}
```

### _posizionaVicinoTray()

Posiziona la finestra appena sotto l'icona tray, allineata al bordo destro:

```dart
static Future<void> _posizionaVicinoTray() async {
  final trayBounds = await trayManager.getBounds();
  final winSize = await windowManager.getSize();
  final x = trayBounds.right - winSize.width;
  final y = trayBounds.bottom + 4;
  await windowManager.setPosition(Offset(x, y));
}
```

```
┌──────────────────────────────────────────────────────┐
│  menubar macOS                         [●] [icona]   │
│                                        ↑             │
│                                  trayBounds          │
└──────────────────────────────────────────────────────┘
                                    ┌───────────┐
                                    │ finestra  │  ← y = trayBounds.bottom + 4
                                    │           │  ← x = trayBounds.right - width
                                    └───────────┘
```

Gli errori (es. `getBounds()` non disponibile) vengono catturati silenziosamente con `debugPrint`.

### gestisciMenuClick(key)

```dart
static Future<void> gestisciMenuClick(String key) async {
  switch (key) {
    case 'toggle': gestisciClick(); break;
    case 'quit':   windowManager.close(); break;
  }
}
```

---

## Integrazione in main.dart

`_MaelstromAppState` implementa i mixin `TrayListener` e `WindowListener`:

```dart
class _MaelstromAppState extends ConsumerState<MaelstromApp>
    with TrayListener, WindowListener {

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }

  // Click sull'icona tray (pulsante sinistro)
  @override
  void onTrayIconMouseDown() => TrayManagerService.gestisciClick();

  // Click su una voce del menu contestuale
  @override
  void onTrayMenuItemClick(MenuItem menuItem) =>
      TrayManagerService.gestisciMenuClick(menuItem.key ?? '');

  // Finestra perde il focus → si nasconde (comportamento popover)
  @override
  void onWindowBlur() => windowManager.hide();
}
```

---

## Configurazione finestra

Impostata in `main.dart` prima del `runApp`:

| Proprietà | Valore | Note |
|-----------|--------|------|
| Dimensioni | 480×580 px | `AppTheme.windowWidth/Height` |
| Ridimensionabile | `false` | Layout fisso |
| Titlebar | `hidden` | Trasparente, mostra comunque traffic lights |
| Skip taskbar | `true` | Non appare nel dock |
| Visibile all'avvio | `false` | Nascosta, appare solo al click tray |

---

## Frosted Glass Effect

Applicato tramite `macos_window_utils`:

```dart
// main.dart
await WindowManipulator.initialize(enableWindowDelegate: false);
WindowManipulator.setMaterial(
  NSVisualEffectViewMaterial.sidebar,
);
```

Il wrapper `FrostedContainer` (`lib/shared/widgets/frosted_container.dart`) usa `TransparentMacOSSidebar` che rende lo sfondo dell'app trasparente, lasciando trasparire l'effetto vetro macOS.

---

## Titolo tray durante timer attivo

Il `TimerNotifier` aggiorna il titolo ogni secondo tramite `_avviaTick()`:

```dart
Timer.periodic(Duration(seconds: 1), (_) {
  TrayManagerService.aggiornaTitolo('● ${state.status.elapsedFormattato}');
  state = state.copyWith(status: state.status);  // rebuild UI
});
```

Quando il timer viene fermato:
```dart
await TrayManagerService.aggiornaTitolo(null);  // → '' (nessun testo)
```

---

## Asset icona tray

**Path**: `assets/images/tray_icon.png`

Icona monocromatica (brandmark W-Tech bianco) ottimizzata per la menubar macOS. Le icone tray macOS seguono le linee guida Apple per le "template images" — devono essere monocromatiche per adattarsi automaticamente a light/dark mode della menubar.
