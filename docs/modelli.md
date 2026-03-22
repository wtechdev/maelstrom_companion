# Modelli Dati

Tutti i modelli sono **immutabili**: campi `final`, costruttori `const`, nessuna mutazione in-place.

---

## Project

**Path**: `lib/core/models/project.dart`

```dart
class Project {
  final int id;
  final String nome;
}
```

| Campo | Tipo | Sorgente API |
|-------|------|-------------|
| `id` | `int` | `json['id']` |
| `nome` | `String` | `json['name']` oppure `json['nome']` |

Usato in: `ProjectsScreen`, `selectedProjectProvider`, `TimerScreen`.

---

## TimesheetEntry

**Path**: `lib/core/models/timesheet_entry.dart`

```dart
class TimesheetEntry {
  final int id;
  final String progetto;       // estratto da project.name
  final DateTime data;
  final double ore;
  final String? descrizione;
}
```

| Campo | Tipo | Sorgente API |
|-------|------|-------------|
| `id` | `int` | `json['id']` |
| `progetto` | `String` | `json['project']['name']` |
| `data` | `DateTime` | `DateTime.parse(json['data'])` |
| `ore` | `double` | `json['ore']` (num o string) |
| `descrizione` | `String?` | `json['descrizione']` |

### Getters

```dart
int get minutiTotali => (ore * 60).round();

String get durataFormattata {
  final h = ore.floor();
  final m = ((ore - h) * 60).round();
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}
```

Usato in: `TimesheetScreen`, `EntryTile`.

---

## TimerStatus

**Path**: `lib/core/models/timer_status.dart`

```dart
class TimerStatus {
  final bool attivo;
  final int? progettoId;
  final String? progettoNome;
  final DateTime? iniziato;
}
```

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `attivo` | `bool` | Timer in esecuzione |
| `progettoId` | `int?` | ID progetto del timer attivo |
| `progettoNome` | `String?` | Nome progetto (dalla selezione locale) |
| `iniziato` | `DateTime?` | Timestamp di avvio |

### Factory methods

```dart
TimerStatus.inattivo()
// → TimerStatus(attivo: false)

TimerStatus.fromJson(json)
// Gestisce due formati risposta:
// 1. getTimerStatus: { "active": true, "timer": { "project_id": 2, "started_at": "..." } }
// 2. startTimer:     costruito manualmente con attivo: true
```

### Getters

```dart
Duration get elapsed =>
    attivo && iniziato != null
        ? DateTime.now().difference(iniziato!)
        : Duration.zero;

String get elapsedFormattato {
  // "HH:MM:SS"
  final d = elapsed;
  return '${d.inHours.toString().padLeft(2,'0')}:'
       '${(d.inMinutes % 60).toString().padLeft(2,'0')}:'
       '${(d.inSeconds % 60).toString().padLeft(2,'0')}';
}
```

Usato in: `TimerNotifier`, `TimerScreen`, `TrayManagerService`.

---

## PendingTimerEntry

**Path**: `lib/core/models/pending_timer_entry.dart`

Modello intermedio che vive tra lo stop del timer e il salvataggio confermato. Esiste solo nello stato `TimerState.pendingEntry`.

```dart
class PendingTimerEntry {
  final int projectId;
  final String? progettoNome;
  final double ore;
  final DateTime startedAt;
  final DateTime stoppedAt;
}
```

| Campo | Tipo | Sorgente |
|-------|------|---------|
| `projectId` | `int` | `json['project_id']` |
| `progettoNome` | `String?` | passato dall'app (non nell'API response) |
| `ore` | `double` | `json['ore']` (num o string) |
| `startedAt` | `DateTime` | `json['started_at']` |
| `stoppedAt` | `DateTime` | `json['stopped_at']` |

### Getter

```dart
String get oreFormattate {
  final h = ore.floor();
  final m = ((ore - h) * 60).round();
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}
```

Usato in: `_ConfermaView` in `TimerScreen`.

---

## TipoAttivita (enum)

**Path**: `lib/core/models/pending_timer_entry.dart`

```dart
enum TipoAttivita {
  sviluppo,
  analisi,
  supporto,
  meeting,
  formazione,
  altro;

  String get value => name;        // valore API: "sviluppo", "analisi", ...
  String get label => switch (this) {
    sviluppo   => 'Sviluppo',
    analisi    => 'Analisi',
    supporto   => 'Supporto',
    meeting    => 'Meeting',
    formazione => 'Formazione',
    altro      => 'Altro',
  };
}
```

Usato in: `_ConfermaView`, `_RegistrazioneManuale`, `TimerNotifier`, `salvaTimeEntry`.

---

## WeekProjectRow

**Path**: `lib/core/models/week_summary.dart`

```dart
class WeekProjectRow {
  final String progetto;
  final List<int> minutiPerGiorno;  // 7 elementi: [lun, mar, mer, gio, ven, sab, dom]
  final int totaleMinuti;
}
```

Usato in: `_Griglia` in `WeekScreen`.

---

## WeekSummary

**Path**: `lib/core/models/week_summary.dart`

```dart
class WeekSummary {
  final DateTime inizioSettimana;
  final DateTime fineSettimana;
  final List<WeekProjectRow> righe;
  final List<int> totaliGiornalieri;  // 7 elementi: minuti per giorno
}
```

### Parsing (fromJson)

Il `fromJson` esegue una trasformazione complessa dalla struttura backend:

```
Backend:
  projects: [{id, name, ...}, ...]      → righe[].progetto
  days: ["2026-03-16", ...]             → asse giorni (7 elementi)
  grid: { "2": {"2026-03-16": 0.25} }  → righe[].minutiPerGiorno
  dayTotals: { "2026-03-16": 0.25 }    → totaliGiornalieri

Dart:
  per ogni project in projects:
    pId = project['id'].toString()
    projGrid = grid[pId] (Map<date, ore_float>) oppure {}
    minutiPerGiorno = days.map(d => (projGrid[d] * 60).round())
    totaleMinuti = sum(minutiPerGiorno)

  totaliGiornalieri = days.map(d => (dayTotals[d] * 60).round())
```

**Quirks PHP gestiti**:
- Array associativo vuoto PHP → `[]` in JSON invece di `{}` → `is Map` check
- Chiavi intere `project_id` → string keys `"2"` in JSON → `.toString()` su `id`
- Valori `decimal` → possono essere string `"2.25"` o number `2.25`

Usato in: `WeekScreen._Griglia`.
