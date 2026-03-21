# Piano UI — Maelstrom Companion App (macOS)

## Contesto

L'app è una Flutter companion per il backend Maelstrom (Laravel 12). Deve vivere esclusivamente nella menubar macOS: nessuna icona nel dock, finestra popover compatta (360×480px) agganciata all'icona della menubar, con tre sezioni navigabili via tab bar inferiore. Il timer attivo mostra il tempo in corso direttamente nel testo della menubar.

---

## Requisiti confermati

| Aspetto | Scelta |
|---------|--------|
| Apertura UI | Popover agganciato all'icona menubar |
| Schermate | Timer rapido, Timesheet oggi, Vista settimanale |
| Stile | macOS nativo — frosted glass, SF Pro, light/dark auto |
| Dock | Nessuna icona (LSUIElement = true) |
| Avvio automatico | Sì (SMAppService al login) |
| Focus lost | Nasconde la finestra |
| Menubar text | `● 01:23:45` quando timer attivo, solo icona altrimenti |
| Navigazione | Tab bar in basso: Timer · Oggi · Settimana |
| Timer UX | Dropdown progetto + Start → Stop con elapsed |
| Dimensioni | 360×480px fissa |
| Primo avvio | Setup inline: URL server + token API → Keychain |

---

## Pacchetti da aggiungere (pubspec.yaml)

```yaml
dependencies:
  tray_manager: ^0.2.3          # icona + menu contestuale menubar
  window_manager: ^0.3.9        # posizionamento, hide/show, focus listener
  macos_window_utils: ^1.4.0    # frosted glass, titlebar trasparente
  flutter_secure_storage: ^9.2.2 # salvataggio token nel Keychain macOS
  flutter_riverpod: ^2.6.1      # state management
  go_router: ^14.6.2            # navigazione tra tab/schermate
  http: ^1.2.2                  # chiamate API REST
  intl: ^0.19.0                 # formattazione date/ore
```

---

## File da creare / modificare

### 1. Configurazione macOS (nativa)

**`macos/Runner/Info.plist`** — aggiungere:
```xml
<key>LSUIElement</key>
<true/>
```
Questo rimuove l'icona dal dock e dalla lista Cmd+Tab.

**`macos/Runner/DebugProfile.entitlements`** e **`Release.entitlements`** — aggiungere:
```xml
<key>com.apple.security.network.client</key>
<true/>
```
Necessario per le chiamate HTTP al backend.

### 2. Struttura lib/

```
lib/
  main.dart                        # bootstrap: tray + window init
  core/
    api/
      api_client.dart              # http client con Bearer token
      api_exception.dart           # errori normalizzati
    auth/
      token_storage.dart           # flutter_secure_storage wrapper
      auth_provider.dart           # Riverpod: stato autenticazione
    models/
      project.dart
      timesheet_entry.dart
      timer_status.dart
      week_summary.dart
  features/
    setup/
      setup_screen.dart            # primo avvio: URL + token
    timer/
      timer_screen.dart            # tab 1: dropdown progetto + start/stop
      timer_provider.dart          # Riverpod: stato timer + polling
    timesheet/
      timesheet_screen.dart        # tab 2: lista registrazioni oggi
      timesheet_provider.dart
    week/
      week_screen.dart             # tab 3: griglia ore settimanale
      week_provider.dart
  shared/
    widgets/
      tab_bar.dart                 # tab bar inferiore (3 tab)
      entry_tile.dart              # riga singola registrazione ore
      frosted_container.dart       # wrapper con sfondo frosted glass
    theme/
      app_theme.dart               # colori, typography, spacing
    tray/
      tray_manager_service.dart    # setup icona + menu contestuale
```

### 3. main.dart — flusso di inizializzazione

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 1. Nascondi finestra all'avvio (compare solo al click tray)
  await windowManager.setSize(const Size(360, 480));
  await windowManager.setResizable(false);
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.hide();

  // 2. Setup icona menubar
  await TrayManagerService.init();

  // 3. Effetto frosted glass
  await Window.setEffect(effect: WindowEffect.sidebar);

  runApp(const ProviderScope(child: MaelstromCompanionApp()));
}
```

### 4. TrayManagerService

- Icona: asset PNG monocromatico (template image)
- Menu contestuale destro: `Apri`, `Impostazioni`, `Esci`
- Al click sinistro: toggle show/hide della finestra popover
- Quando timer attivo: aggiorna il titolo tray con `● HH:mm:ss` ogni secondo

### 5. WindowManager setup

- `onWindowBlur`: chiama `windowManager.hide()`
- Posizionamento al click tray: calcola coordinate dall'icona tray → posiziona la finestra sotto di essa nell'angolo top-right

### 6. Navigazione (go_router)

```
/setup          → SetupScreen (se token assente)
/home           → shell con tab bar
  /home/timer   → TimerScreen
  /home/today   → TimesheetScreen
  /home/week    → WeekScreen
```

### 7. SetupScreen (primo avvio)

- Campo URL server (`http://localhost:8000`)
- Campo token (oscurato, `obscureText: true`)
- Bottone "Connetti" → chiama `GET /api/v1/me` per validare → salva in Keychain → redirect a `/home`

### 8. TimerScreen

**Stato idle:**
- Dropdown (DropdownButton) con lista progetti da `/api/v1/me/projects`
- Bottone `▶ Avvia timer`

**Stato attivo:**
- Nome progetto + `●` animato
- Contatore `HH:mm:ss` aggiornato ogni secondo (Timer.periodic)
- Bottone `■ Ferma e salva` → `POST /api/v1/me/timer/stop`

### 9. TimesheetScreen (Oggi)

- Lista scrollabile delle registrazioni di oggi da `/api/v1/me/timesheet`
- Ogni riga: nome progetto, durata, orario inizio–fine
- Totale ore in fondo
- Pull-to-refresh

### 10. WeekScreen (Settimana)

- Griglia compatta: righe = progetti, colonne = giorni lun–ven
- Dati da `/api/v1/me/timesheet/week`
- Totale colonna (giorno) e totale riga (progetto)
- Navigazione settimana precedente/successiva con frecce

---

## Flusso timer nella menubar

```
Timer inattivo  → icona sola (es. ⏱)
Timer attivo    → "● 01:23:45" (aggiornato ogni secondo via Timer.periodic)
```

`TrayManagerService` osserva `TimerProvider` via Riverpod ref e chiama
`trayManager.setTitle(elapsed)` ad ogni tick.

---

## Avvio automatico al login

Usare `SMAppService` (disponibile da macOS 13) tramite un plugin Flutter
o chiamata diretta al canale Swift in `macos/Runner/AppDelegate.swift`.

Alternativa più semplice e compatibile: creare un `LaunchAgent` plist in
`~/Library/LaunchAgents/` alla prima esecuzione.

---

## Ordine di implementazione (fasi)

1. **Fase 0** — Setup progetto: aggiungere dipendenze, configurare `Info.plist`, entitlements, asset icona tray
2. **Fase 1** — Shell macOS: `main.dart` con window init + tray init + frosted glass; finestra vuota che appare/scompare al click
3. **Fase 2** — Auth: `SetupScreen`, `TokenStorage`, `ApiClient` con Bearer; validazione token al primo lancio
4. **Fase 3** — Navigazione: go_router + tab bar inferiore + schermate placeholder
5. **Fase 4** — TimerScreen: provider, polling status, start/stop, aggiornamento tray label
6. **Fase 5** — TimesheetScreen: lista oggi, pull-to-refresh
7. **Fase 6** — WeekScreen: griglia settimanale, navigazione settimane
8. **Fase 7** — Polish: dark/light mode, animazioni, avvio al login

---

## Verifica (per ogni fase)

```bash
flutter analyze          # zero warning
flutter run -d macos     # smoke test visivo
flutter test             # test unitari provider + api_client (mock http)
```

Test manuali chiave:
- Click icona tray → popover appare in alto a destra
- Click fuori → popover si nasconde
- Primo avvio → SetupScreen → inserimento token valido → redirect home
- Start timer → label menubar si aggiorna ogni secondo
- Stop timer → label torna a icona sola
