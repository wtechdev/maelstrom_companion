# Timer e Registrazione Ore

## Panoramica

La tab "Registra" gestisce tre funzionalità:
1. **Avvia/ferma timer** — traccia il tempo in tempo reale con aggiornamento nella menubar
2. **Inserisci ore manualmente** — form per registrare ore a posteriori
3. **Conferma salvataggio** — dopo lo stop del timer, richiede tipo attività e descrizione

---

## File coinvolti

| File | Responsabilità |
|------|---------------|
| `lib/features/timer/timer_screen.dart` | UI con 4 view: idle, attivo, manuale, conferma |
| `lib/features/timer/timer_provider.dart` | StateNotifier con logica timer, tick, salvataggio |
| `lib/core/models/timer_status.dart` | Stato timer corrente + elapsed time |
| `lib/core/models/pending_timer_entry.dart` | Entry intermedia post-stop + enum TipoAttivita |

---

## TimerState e TimerNotifier

**Path**: `lib/features/timer/timer_provider.dart`

### TimerState

```dart
class TimerState {
  final TimerStatus status;      // stato timer (attivo/inattivo, progetto, elapsed)
  final bool loading;            // operazione in corso
  final String? errore;          // messaggio errore
  final PendingTimerEntry? pendingEntry;  // entry da confermare post-stop
}
```

### TimerNotifier — metodi pubblici

| Metodo | Descrizione |
|--------|-------------|
| `carica()` | Carica lo stato timer dal backend all'avvio |
| `avviaTimer(projectId)` | `POST /timer/start` → aggiorna stato → avvia tick |
| `fermaTimer()` | `POST /timer/stop` → ferma tick → imposta `pendingEntry` |
| `confermaSalvataggio(tipoAttivita, descrizione?)` | `POST /timesheet` → cancella `pendingEntry` |
| `annullaSalvataggio()` | Cancella `pendingEntry` senza salvare |
| `registraOreManuale(projectId, ore, tipoAttivita, descrizione?)` | `POST /timesheet` diretto |

### Tick timer

```dart
void _avviaTick() {
  _tickTimer = Timer.periodic(Duration(seconds: 1), (t) {
    if (state.status.attivo) {
      TrayManagerService.aggiornaTitolo('● ${state.status.elapsedFormattato}');
      state = state.copyWith(status: state.status);  // forza rebuild UI
    }
  });
}
```

Il tick aggiorna l'icona menubar ogni secondo e forza il rebuild della UI per aggiornare il contatore.

---

## TimerScreen — logica di routing interno

**Path**: `lib/features/timer/timer_screen.dart`

```dart
// Priorità di visualizzazione
if (state.pendingEntry != null)    → _ConfermaView
else if (_mostraFormManuale)       → _RegistrazioneManuale
else if (state.status.attivo)      → _TimerAttivoView
else                               → _TimerIdleView
```

---

## View 1: _TimerIdleView

Mostrata quando nessun timer è attivo e non si sta inserendo a mano.

```
┌─────────────────────────────┐
│  Progetto: App Mobile Beta  │
│                    [Cambia] │
│                             │
│  [▶ Avvia timer]            │  ← FilledButton (verde)
│  [+ Inserisci ore]          │  ← OutlinedButton
└─────────────────────────────┘
```

- Se nessun progetto è selezionato, mostra solo "Seleziona un progetto" e nasconde i pulsanti
- "Cambia" naviga a `/home/projects`
- "Inserisci ore" imposta `_mostraFormManuale = true`

---

## View 2: _TimerAttivoView

Mostrata quando il timer è in esecuzione.

```
┌─────────────────────────────┐
│  ● App Mobile Beta          │
│                             │
│        01:23:45             │  ← fontSize 48, aggiornato ogni secondo
│                             │
│  [■ Ferma e salva]          │  ← OutlinedButton rosso
└─────────────────────────────┘
```

Il contatore legge `state.status.elapsedFormattato` che calcola `DateTime.now() - iniziato`.

---

## View 3: _RegistrazioneManuale

Form per inserimento ore a mano. Appare dopo click "Inserisci ore".

```
┌─────────────────────────────┐
│  App Mobile Beta            │
│                             │
│    [-]   1h 30m   [+]       │  ← stepper ±0.25h
│                             │
│  Tipo attività:             │
│  [sviluppo] [analisi]       │
│  [supporto] [meeting]       │
│  [formazione] [altro]       │
│                             │
│  Descrizione (opzionale):   │
│  [________________________] │
│                             │
│  [errore]                   │
│  [X]           [Salva ✓]    │
└─────────────────────────────┘
```

### Stepper ore

- Passo: ±0.25h (15 minuti)
- Range: 0.25h – 24h
- Display: `_oreFormattate` → `"1h"` | `"1h 30m"` | `"0h 15m"`

### Tipo attività (TipoAttivita enum)

| Valore | Label |
|--------|-------|
| `sviluppo` | Sviluppo |
| `analisi` | Analisi |
| `supporto` | Supporto |
| `meeting` | Meeting |
| `formazione` | Formazione |
| `altro` | Altro |

Le pill tipo attività sono selezionabili (una sola alla volta). Il salvataggio richiede obbligatoriamente la selezione di un tipo.

### Flusso salvataggio

```
_salva()
  └─ notifier.registraOreManuale(projectId, ore, tipoAttivita, descrizione?)
      └─ client.salvaTimeEntry(...)
          → POST /api/v1/me/timesheet
  └─ Se OK:
      ref.invalidate(timesheetProvider)  ← aggiorna tab "Oggi"
      ref.invalidate(weekProvider)       ← aggiorna tab "Settimana"
      setState(_mostraFormManuale = false)
```

---

## View 4: _ConfermaView

Mostrata dopo `fermaTimer()`. Contiene i dati del timer appena fermato e richiede tipo attività e descrizione prima di salvare.

```
┌─────────────────────────────┐
│  Salva registrazione        │
│                             │
│  Progetto: App Mobile Beta  │
│  Ore: 1h 30m                │
│  Dalle 09:00 alle 10:30     │
│                             │
│  Tipo attività:             │
│  [sviluppo] [analisi] ...   │
│                             │
│  Descrizione:               │
│  [________________________] │
│                             │
│  [errore]                   │
│  [Annulla ✗]  [Salva ✓]     │
└─────────────────────────────┘
```

### Flusso conferma

```
Salva:
  notifier.confermaSalvataggio(tipoAttivita, descrizione?)
    └─ client.salvaTimeEntry(projectId, ore, DateTime.now(), ...)
        → POST /api/v1/me/timesheet

  ref.listen(timerProvider):
    Se prev.pendingEntry != null && next.pendingEntry == null && no errore:
      ref.invalidate(timesheetProvider)
      ref.invalidate(weekProvider)

Annulla:
  notifier.annullaSalvataggio()
    → clearPending (nessuna chiamata API)
```

**Nota**: la data salvata è `DateTime.now()` (data di conferma), non la data di inizio del timer. Questo garantisce che la registrazione appaia nel timesheet del giorno in cui viene confermata.

---

## TimerStatus

**Path**: `lib/core/models/timer_status.dart`

```dart
class TimerStatus {
  final bool attivo;
  final int? progettoId;
  final String? progettoNome;
  final DateTime? iniziato;

  // Calcola il tempo trascorso
  Duration get elapsed => attivo && iniziato != null
      ? DateTime.now().difference(iniziato!)
      : Duration.zero;

  // Formatta come HH:MM:SS
  String get elapsedFormattato => ...
}
```

Il `fromJson` gestisce sia la risposta di `getTimerStatus` (che ha `active`/`running`) che quella di `startTimer` (che annida i dati in `timer: {}`).

---

## PendingTimerEntry

**Path**: `lib/core/models/pending_timer_entry.dart`

Modello intermedio creato dopo `stopTimer()`. Contiene i dati per la schermata di conferma.

```dart
class PendingTimerEntry {
  final int projectId;
  final String? progettoNome;
  final double ore;           // calcolato dal backend
  final DateTime startedAt;
  final DateTime stoppedAt;

  String get oreFormattate => ...  // "1h 30m"
}
```

---

## Endpoint API

```
GET  /api/v1/me/timer/status
     Response: { "active": false } | { "active": true, "timer": { "project_id": 2, "started_at": "..." } }

POST /api/v1/me/timer/start
     Body: { "project_id": 2 }
     Response: { "success": true, "timer": { "project_id": 2, "started_at": "..." } }

POST /api/v1/me/timer/stop
     Response: { "project_id": 2, "ore": 1.5, "started_at": "...", "stopped_at": "..." }

POST /api/v1/me/timesheet
     Body: { "project_id": 2, "data": "2026-03-22", "ore": 1.5,
             "tipo_attivita": "sviluppo", "descrizione": "..." }
     Response: { "data": { ...TimeEntry... } }
```

**Nota backend**: `stopTimer` usa la Laravel Cache (TTL 24h) per memorizzare il timer. Non crea una `TimeEntry` — quella viene creata solo da `POST /timesheet` in fase di conferma.
