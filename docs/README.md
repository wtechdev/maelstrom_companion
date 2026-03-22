# Documentazione Tecnica — Maelstrom Companion App

App macOS Flutter per la gestione timesheet e timer del backend **Maelstrom** (Laravel 12).
Vive esclusivamente nella menubar macOS (nessuna icona nel dock) e si apre come popover al click sull'icona tray.

---

## Indice

| File | Descrizione |
|------|-------------|
| [architettura.md](architettura.md) | Struttura generale, dipendenze, flusso dati, pattern |
| [autenticazione.md](autenticazione.md) | Setup iniziale, login, salvataggio credenziali |
| [progetto.md](progetto.md) | Selezione progetto attivo |
| [timer.md](timer.md) | Timer start/stop, registrazione ore manuali, conferma salvataggio |
| [timesheet-oggi.md](timesheet-oggi.md) | Vista registrazioni del giorno |
| [settimana.md](settimana.md) | Griglia settimanale ore per progetto |
| [api-client.md](api-client.md) | Client HTTP, endpoint, gestione errori |
| [modelli.md](modelli.md) | Modelli dati (Project, TimesheetEntry, TimerStatus, WeekSummary, …) |
| [tray-manager.md](tray-manager.md) | Gestione icona menubar, posizionamento finestra, titolo timer |

---

## Avvio rapido

```bash
flutter run -d macos          # sviluppo
flutter build macos           # release
flutter analyze               # analisi statica
dart format lib/ test/        # formattazione
```

## Stack tecnologico

- **Flutter** 3.x — framework UI multiplatform
- **Dart** 3.x — linguaggio
- **Riverpod** 2.6 — state management
- **go_router** 14.6 — navigazione dichiarativa
- **tray_manager** / **window_manager** — integrazione menubar macOS
- **macos_window_utils** — frosted glass effect
- **http** — client HTTP minimale
- **intl** — localizzazione italiana
- **path_provider** — persistenza credenziali su file locale
