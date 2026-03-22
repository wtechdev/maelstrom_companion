# Architettura — Maelstrom Companion App

## Struttura cartelle

```
lib/
├── main.dart                          # Entry point, inizializzazione macOS
├── app_router.dart                    # Routing GoRouter + redirect auth
├── core/
│   ├── auth/
│   │   ├── auth_provider.dart         # Provider autenticazione e ApiClient
│   │   └── token_storage.dart         # Persistenza credenziali su file JSON
│   ├── api/
│   │   ├── api_client.dart            # Client HTTP con tutti gli endpoint
│   │   └── api_exception.dart         # Eccezione normalizzata per errori API
│   ├── models/
│   │   ├── project.dart
│   │   ├── timesheet_entry.dart
│   │   ├── timer_status.dart
│   │   ├── pending_timer_entry.dart   # Entry intermedia post-stop timer
│   │   └── week_summary.dart
│   └── providers/
│       └── selected_project_provider.dart
├── features/
│   ├── setup/
│   │   └── setup_screen.dart
│   ├── shell/
│   │   └── home_shell.dart            # Container principale con tab bar
│   ├── projects/
│   │   └── projects_screen.dart
│   ├── timer/
│   │   ├── timer_screen.dart
│   │   └── timer_provider.dart
│   ├── timesheet/
│   │   ├── timesheet_screen.dart
│   │   └── timesheet_provider.dart
│   └── week/
│       ├── week_screen.dart
│       └── week_provider.dart
└── shared/
    ├── theme/
    │   └── app_theme.dart
    ├── widgets/
    │   ├── frosted_container.dart
    │   ├── entry_tile.dart
    │   └── wtech_logo.dart
    └── tray/
        └── tray_manager_service.dart
```

---

## Dipendenze principali

| Pacchetto | Versione | Uso |
|-----------|----------|-----|
| `flutter_riverpod` | ^2.6.1 | State management |
| `go_router` | ^14.6.2 | Navigazione dichiarativa con redirect |
| `http` | ^1.2.2 | Client HTTP per le API REST |
| `tray_manager` | ^0.2.3 | Icona e menu contestuale menubar macOS |
| `window_manager` | ^0.3.9 | Dimensioni, posizione, visibilità finestra |
| `macos_window_utils` | ^1.4.0 | Frosted glass effect (NSVisualEffectView) |
| `intl` | ^0.19.0 | Formattazione date in italiano |
| `path_provider` | ^2.1.5 | Percorso Application Support per credenziali |
| `flutter_secure_storage` | ^9.2.2 | Incluso ma non usato (richiede code signing) |

---

## Routing

```
Initial location: /home/projects

Redirect:
  - NOT autenticato AND NOT /setup → /setup
  - Autenticato AND /setup → /home/projects

/setup                      → SetupScreen
/home  (StatefulShellRoute) → HomeShell
  /home/projects            → ProjectsScreen  (tab 0)
  /home/timer               → TimerScreen     (tab 1)
  /home/today               → TimesheetScreen (tab 2)
  /home/week                → WeekScreen      (tab 3)
```

Il redirect è reattivo: reagisce automaticamente alle variazioni di `authStateProvider`.

---

## State Management (Riverpod)

### Tipologie di provider usate

| Tipo | Provider | Descrizione |
|------|----------|-------------|
| `Provider<T>` | `tokenStorageProvider` | Singleton read-only |
| `FutureProvider<bool>` | `authStateProvider` | Verifica asincrona credenziali |
| `FutureProvider<ApiClient?>` | `apiClientProvider` | Costruisce il client HTTP |
| `StateProvider<Project?>` | `selectedProjectProvider` | Progetto selezionato globalmente |
| `StateNotifierProvider` | `timerProvider` | Stato timer + notifier |
| `StateNotifierProvider` | `timesheetProvider` | Registrazioni di oggi |
| `StateNotifierProvider` | `weekProvider` | Vista settimanale |

### Pattern StateNotifier

Tutti i provider complessi seguono il pattern:

```dart
// 1. Stato immutabile
class MyState {
  final bool loading;
  final String? errore;
  MyState copyWith({bool? loading, ...}) => MyState(...);
}

// 2. Notifier con logica
class MyNotifier extends StateNotifier<MyState> {
  final ApiClient _client;
  MyNotifier(this._client) : super(MyState()) { carica(); }

  Future<void> carica() async {
    state = state.copyWith(loading: true);
    try {
      final data = await _client.fetch();
      state = state.copyWith(data: data, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, errore: '$e');
    }
  }
}

// 3. Provider dichiarato a livello top
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  final client = ref.watch(apiClientProvider).valueOrNull;
  if (client == null) throw Exception('client non disponibile');
  return MyNotifier(client);
});
```

---

## Sequenza di inizializzazione (main.dart)

```
1. WidgetsFlutterBinding.ensureInitialized()
2. initializeDateFormatting('it')          — locale italiano per intl
3. windowManager.ensureInitialized()
4. windowManager.setSize(480x580)
5. windowManager.setResizable(false)
6. windowManager.setTitleBarStyle(hidden)
7. windowManager.setSkipTaskbar(true)
8. WindowManipulator.initialize()
9. WindowManipulator.setMaterial(sidebar)  — frosted glass
10. TrayManagerService.init()              — icona + menu
11. runApp(ProviderScope(MaelstromApp))
```

---

## Flusso dati end-to-end

### Primo avvio

```
SetupScreen → ApiClient.login(email, password)
           → TokenStorage.salva(url, token)
           → invalidate authStateProvider, apiClientProvider
           → redirect /home/projects
```

### Navigazione normale

```
authStateProvider (FutureProvider<bool>)
  └─ TokenStorage.haCredenziali()
      └─ GoRouter redirect
          └─ HomeShell (tab bar)
              ├─ ProjectsScreen  ← apiClientProvider → client.getProjects()
              ├─ TimerScreen     ← timerProvider → client.getTimerStatus()
              ├─ TimesheetScreen ← timesheetProvider → client.getTimesheetOggi()
              └─ WeekScreen      ← weekProvider → client.getTimesheetWeek()
```

### Invalidazione cross-provider

Dopo ogni salvataggio registrazione (timer o manuale):

```
ref.invalidate(timesheetProvider)  → ricarica lista "Oggi"
ref.invalidate(weekProvider)       → ricarica griglia settimanale
```

---

## Configurazione macOS

### Info.plist (macos/Runner/Info.plist)

```xml
<key>LSUIElement</key>
<true/>
```
Rimuove l'icona dal dock e da Cmd+Tab. L'app è accessibile solo dalla menubar.

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key><true/>
</dict>
```
Permette connessioni HTTP a localhost (necessario in sviluppo).

### Entitlements

```xml
<!-- DebugProfile.entitlements e Release.entitlements -->
<key>com.apple.security.network.client</key>
<true/>
```
Necessario per le chiamate HTTP al backend.

---

## Dimensioni e layout finestra

- **Dimensioni**: 480×580 px, non ridimensionabile
- **Titolo**: nascosto (`TitleBarStyle.hidden`)
- **Clearance traffic lights**: 28 px di padding top su tutti gli header
- **Posizionamento**: automatico sotto l'icona tray al click (vedi [tray-manager.md](tray-manager.md))

---

## Pattern immutabilità

Tutti i model e gli state usano `const` constructor e `copyWith()`. Nessuna mutazione diretta degli oggetti. Esempio:

```dart
// CORRETTO
state = state.copyWith(loading: false, errore: msg);

// SBAGLIATO
state.loading = false;  // non compila — campi final
```

---

## Gestione errori

| Layer | Meccanismo |
|-------|-----------|
| HTTP | `_parseResponse()` → lancia `ApiException(statusCode, message)` |
| Notifier | `catch (e) { state = state.copyWith(errore: ...) }` |
| UI | `if (state.errore != null) → widget errore con pulsante Riprova` |
| ApiException 401/403 | Messaggi specifici in SetupScreen |
