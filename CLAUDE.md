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

## Workflow Orchestration

- **Plan Mode**: Entrare in plan mode per qualsiasi task non banale (3+ step o decisioni architetturali).
- **Re-planning**: Se qualcosa va storto, STOP e ri-pianificare subito — non forzare.
- **Specs**: Scrivere specifiche dettagliate prima di codificare per ridurre ambiguità.
- **Subagents**: Usare subagenti liberamente per ricerche o analisi parallele — un task per subagente.

## Git & Changelog

- **No auto-commit/push**: Mai eseguire commit o push automatici. L'utente deve approvare esplicitamente ogni operazione.
- **No auto-push tag/release**: Non eseguire mai `git push`, `git push origin <tag>` o qualsiasi operazione di push (inclusi tag e release) senza esplicita istruzione dell'utente. Questo vale anche dopo commit, tag o build — preparare tutto localmente e attendere il via.
- **Branch workflow**: Su branch feature/bugfix, aggiornare `CHANGELOG-[branch-name].md` nella root (formato [Keep a Changelog](https://keepachangelog.com/)).
- **Main workflow**: Su main, aggiornare la sezione `[Unreleased]` di `CHANGELOG.md`.
- **Merge/PR**: Al merge, integrare il changelog del branch nel `CHANGELOG.md` principale ed eliminare il file temporaneo.
- **Versioning X.Y.Z**: Z = sub-release progressiva del giorno (automatica), Y = release del giorno lavorativo (automatica), X = versione software (manuale, chiedere all'utente).
- **Scope rigidity**: Implementare solo ciò che è presente nel codice del progetto. No assunzioni basate su standard esterni.

## Documentation & Task Management

- **Functional analysis**: Creare un file `.md` in `/docs` per ogni funzione di piattaforma.
- **Feature TODOs**: Per implementazioni importanti, creare `TODO.md` in `/docs`. Rileggere dopo context compression.
- **Self-improvement**: Dopo ogni correzione, aggiornare `tasks/lessons.md` con il pattern per evitare errori ripetuti.

## Technical Standards

- **Dart**: Usare type hints espliciti ovunque. Preferire `final` e pattern immutabili.
- **Commenti**: Documentazione del codice in **italiano**.
- **Testing**: Test con `flutter_test`. Eseguire e far passare i test prima di marcare un task come completo.
- **Lint**: Eseguire `flutter analyze` prima di ogni commit.

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

## Core Principles

- **Semplicità**: Ogni modifica deve essere la più semplice possibile. Impatto minimale.
- **No scorciatoie**: Trovare le cause radice. Zero fix temporanei. Standard da senior developer.
- **Verifica prima di "done"**: Mai marcare un task come completato senza averlo provato con test, log e verifica manuale.
