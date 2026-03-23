# Changelog

Tutte le modifiche rilevanti a questo progetto sono documentate in questo file.
Formato basato su [Keep a Changelog](https://keepachangelog.com/it/1.0.0/).

---

## [1.0.1] — 2026-03-23

### Corretto
- **Vista settimanale**: le ore per singolo progetto non venivano mostrate (compariva "-") a causa di una regressione nell'API backend che restituiva oggetti invece di valori numerici

---

## [1.0.0] — 2026-03-23

### Aggiunto
- **Context menu tray**: tasto destro sull'icona menubar mostra menu con voci Progetti, Registra, Oggi, Settimana e Esci
- **Navigazione da tray**: ogni voce mostra la finestra (se nascosta) e naviga direttamente alla sezione
- **Pulsante Logout**: icona nell'header dell'app (accanto al logo) per fare logout e tornare alla schermata di setup

### Modificato
- **Finestra ridimensionabile**: rimosso il vincolo di dimensione massima, la finestra può essere allargata liberamente (minimo 480×580)
- **Fix Esci**: il tasto "Esci" nel menu tray ora usa `exit(0)` per terminare davvero il processo (prima usava `windowManager.close()` che non chiudeva l'app)
- **Fix redirect auth**: il redirect GoRouter ora attende il risultato reale del controllo credenziali invece di usare il valore parzialmente caricato, eliminando la race condition che mostrava il login anche con sessione valida

---

## [0.1.0-beta.5] — 2026-03-22

### Modificato
- **Sfondo DMG**: sostituito gradiente generato con immagine brandizzata W Tech (Gemini)
- `generate_background.py` ora ridimensiona `dmg_background_source.png` a 1200×800 invece di generare il gradiente

---

## [0.1.0-beta.4] — 2026-03-22

### Modificato
- **Nome app**: rinominata da `maelstrom_companion` a `Maelstrom Companion` (bundle, titlebar e Finder)

---

## [0.1.0-beta.3] — 2026-03-22

### Corretto
- **CI**: estrazione note CHANGELOG via script Python dedicato (`installer/extract_changelog.py`), risolve incompatibilità `head -n -1` su macOS runner

---

## [0.1.0-beta.2] — 2026-03-22

### Aggiunto
- **Icona app**: brandmark W-Tech a colori sostituisce l'icona placeholder Flutter

### Corretto
- **CI**: rimosso `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` che causava il fallimento della beta 1 (le action `checkout@v4` non supportano ancora Node.js 24)
- **CI**: aggiunto `--break-system-packages` a `pip3 install Pillow` per compatibilità con macOS runner GitHub Actions
- **CI**: aggiunto step di verifica esistenza DMG dopo creazione

---

## [0.1.0-beta.1] — 2026-03-22

### Aggiunto
- **DMG Installer**: distribuzione tramite DMG brandizzato macOS
- **CI/CD GitHub Actions**: build automatica ad ogni push su `master` (nightly artifact) e ad ogni tag `v*.*.*` (GitHub Release con DMG allegato)
- **Sfondo brandizzato DMG**: generato via script Python con Pillow, gradiente scuro Maelstrom, testo "Maelstrom Companion" e istruzione di installazione
- **Script build locale**: `installer/build_dmg.sh` per creare il DMG in locale senza CI

---

## [0.1.0] — 2026-03-22

### Aggiunto
- **Registrazione ore manuale**: tab "Registra" con pulsante "Inserisci ore" che apre un form con stepper ±0.25h (range 0.25–24h), selezione tipo attività e campo descrizione
- **Conferma stop timer**: dopo aver fermato il timer appare una schermata di conferma per selezionare tipo attività e aggiungere una descrizione prima di salvare
- **Vista settimanale completa**: griglia lun–dom (7 giorni) con totali per progetto e per giorno
- **Icona tray**: brandmark W-Tech monocromatico (`brandmark-w-tech_w.png`)
- **Logo W-Tech**: presente nella schermata di login e nell'header dell'app
- **Schermata setup**: URL server nascosto dietro icona ingranaggio, login con email + password
- **Avvio automatico al login**: configurazione via menubar macOS
- **Effetto frosted glass**: finestra con sfondo traslucido macOS sidebar
- **Posizionamento automatico**: finestra appare sotto l'icona della menubar al click

### Modificato
- Tab "Timer" rinominata in "Registra"
- Finestra ridimensionata a 480×580px per accomodare la griglia settimanale
- `weekProvider` invalidato automaticamente dopo ogni salvataggio registrazione

### Corretto
- `TimerStatus.fromJson`: lettura di `started_at` dal campo annidato `json['timer']`
- `WeekSummary`: grid ora somma le ore per (progetto, giorno) invece di sovrascrivere con l'ultima entry
- `WeekSummary`: cast robusto del grid con controllo `is Map` prima del cast
- `TimesheetEntry`: parsing campi allineato alla struttura reale dell'API (`project.name`, `data`, `ore`)
- Inizializzazione locale italiano (`initializeDateFormatting('it')`) per evitare `LocaleDataException`
- Aggiornamento schermata "Oggi" e "Settimana" dopo salvataggio senza refresh manuale

### Architettura
- State management con **Riverpod** (`StateNotifierProvider`, `FutureProvider`)
- Navigazione con **go_router** (4 branch: Progetto, Registra, Oggi, Settimana)
- Token salvato in file locale (`maelstrom_credentials.json`) via `path_provider`
- API client con Bearer token, gestione errori via `ApiException`
- `TrayManagerService`: gestione icona menubar, menu contestuale, toggle finestra, titolo timer attivo
- `PendingTimerEntry`: modello intermedio tra stop timer e salvataggio TimeEntry

---

## [0.0.1] — 2026-03-21

### Aggiunto
- Inizializzazione progetto Flutter companion app (target primario: macOS)
- Struttura cartelle `core/`, `features/`, `shared/`
- Configurazione macOS: `LSUIElement=true` (nessuna icona nel dock), entitlements rete
- Dipendenze: `tray_manager`, `window_manager`, `macos_window_utils`, `flutter_riverpod`, `go_router`, `http`, `intl`, `path_provider`
