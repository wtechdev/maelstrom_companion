# Maelstrom Companion App

App macOS companion per il backend [Maelstrom](https://github.com/wtechdev/maelstrom) (Laravel 12).
Vive nella menubar macOS come popover compatto — nessuna icona nel dock.

## Funzionalità

- **Timer** — avvia e ferma il timer su un progetto, con aggiornamento in tempo reale nella menubar
- **Registrazione ore manuale** — inserimento ore a posteriori con tipo attività e descrizione
- **Timesheet oggi** — lista delle registrazioni del giorno corrente con totale ore
- **Vista settimanale** — griglia ore lun–dom per progetto con navigazione tra settimane
- **Frosted glass** — interfaccia con effetto vetro nativo macOS

## Requisiti

- macOS 13+
- Flutter 3.x
- Backend Maelstrom attivo e raggiungibile

## Avvio rapido

```bash
flutter pub get
flutter run -d macos
```

Al primo avvio, inserire l'URL del backend (icona ingranaggio) e le credenziali di accesso.

## Comandi utili

```bash
flutter run -d macos          # sviluppo con hot reload
flutter build macos           # build release
flutter analyze               # analisi statica
dart format lib/ test/        # formattazione codice
flutter test                  # esegui test
```

## Documentazione

La documentazione tecnica e funzionale è in [`docs/`](docs/README.md):

| Documento | Contenuto |
|-----------|-----------|
| [architettura.md](docs/architettura.md) | Struttura progetto, routing, state management, pattern |
| [autenticazione.md](docs/autenticazione.md) | Login, salvataggio credenziali, provider auth |
| [progetto.md](docs/progetto.md) | Selezione progetto attivo |
| [timer.md](docs/timer.md) | Timer start/stop, registrazione manuale, conferma |
| [timesheet-oggi.md](docs/timesheet-oggi.md) | Vista registrazioni giornaliere |
| [settimana.md](docs/settimana.md) | Griglia settimanale, navigazione, parsing dati |
| [api-client.md](docs/api-client.md) | Client HTTP, endpoint, gestione errori |
| [modelli.md](docs/modelli.md) | Modelli dati (Project, TimesheetEntry, TimerStatus, …) |
| [tray-manager.md](docs/tray-manager.md) | Icona menubar, posizionamento, effetto vetro |

## Stack

- **Flutter** / **Dart** — UI e logica
- **Riverpod** 2.6 — state management
- **go_router** 14.6 — navigazione
- **tray_manager** / **window_manager** — integrazione macOS
- **macos_window_utils** — effetto frosted glass
- **http** — client HTTP
- **intl** — localizzazione italiana
- **path_provider** — persistenza credenziali
