# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Companion app Flutter (target primario: **macOS**) per il backend **Maelstrom** (Laravel 12). Consuma le API REST `/api/v1/me/*` con autenticazione via token personali (header `Authorization: Bearer <token>`).

Backend di riferimento: `/Users/wayne/Code/maelstrom` — documentazione API in `docs/API.md`.

## Commands

```bash
# Sviluppo su macOS
flutter run -d macos

# Build release macOS
flutter build macos

# Test
flutter test                          # tutti i test
flutter test test/path/to/test.dart   # singolo file
flutter test --name "nome test"       # filtro per nome

# Analisi statica
flutter analyze

# Formattazione
dart format lib/ test/

# Dipendenze
flutter pub get
flutter pub upgrade
```

## Architecture

Progetto allo stato iniziale (`lib/main.dart` = skeleton). Architettura da costruire su questi pilastri:

### Struttura cartelle attesa
```
lib/
  core/
    api/          # client HTTP, interceptors, error handling
    auth/         # gestione token, secure storage
    models/       # modelli condivisi
  features/
    auth/         # login, token setup
    timesheet/    # registrazione ore, vista settimanale
    timer/        # timer in-app start/stop
    absences/     # gestione assenze
    profile/      # profilo /me
  shared/
    widgets/      # componenti riutilizzabili
    theme/        # tema macOS-native
```

### API Backend
- Base URL configurabile (dev: `http://localhost:8000`)
- Auth: `Authorization: Bearer <token>` — token salvato nel Keychain macOS via `flutter_secure_storage`
- Endpoint disponibili:
  - `GET /api/v1/me` — profilo utente
  - `GET/POST /api/v1/me/timesheet` — registrazioni ore
  - `GET /api/v1/me/timesheet/week` — vista settimanale
  - `GET /api/v1/me/timesheet/stats` — statistiche
  - `GET /api/v1/me/timer/status`, `POST /api/v1/me/timer/start|stop` — timer
  - `GET/POST /api/v1/me/absences` — assenze
  - `GET /api/v1/me/projects` — progetti disponibili

### Convenzioni da seguire
- State management: **Riverpod** (preferito per app Flutter macOS)
- Repository pattern per l'accesso alle API
- Navigazione con **go_router**
- Secrets nel Keychain con **flutter_secure_storage**

## Git Workflow

- **Non committare mai automaticamente** — i commit sono espliciti dall'utente
- **Non fare mai push** — gestito manualmente
- Commit message in italiano, formato `<type>: <descrizione>`
- Aggiornare `CHANGELOG.md` prima di ogni commit
