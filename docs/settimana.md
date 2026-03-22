# Vista Settimanale

## Panoramica

La tab "Settimana" mostra una griglia delle ore registrate nella settimana corrente (lunedì–domenica), organizzata per progetto e giorno. Permette di navigare alle settimane precedenti tramite frecce.

---

## File coinvolti

| File | Responsabilità |
|------|---------------|
| `lib/features/week/week_screen.dart` | UI griglia settimanale + navigazione |
| `lib/features/week/week_provider.dart` | StateNotifier con navigazione settimane |
| `lib/core/models/week_summary.dart` | Modelli `WeekSummary` e `WeekProjectRow` |

---

## Modelli dati

**Path**: `lib/core/models/week_summary.dart`

### WeekProjectRow

```dart
class WeekProjectRow {
  final String progetto;
  final List<int> minutiPerGiorno;  // 7 elementi: lun-dom in minuti
  final int totaleMinuti;
}
```

### WeekSummary

```dart
class WeekSummary {
  final DateTime inizioSettimana;
  final DateTime fineSettimana;
  final List<WeekProjectRow> righe;
  final List<int> totaliGiornalieri;  // 7 elementi: minuti per giorno
}
```

### Parsing JSON (fromJson)

Il backend restituisce una struttura complessa:

```json
{
  "weekStart": "2026-03-16T00:00:00.000000Z",
  "weekEnd":   "2026-03-22T23:59:59.999999Z",
  "days":      ["2026-03-16", "2026-03-17", ..., "2026-03-22"],
  "projects":  [ {"id": 2, "name": "App Mobile Beta"}, ... ],
  "grid":      { "2": {"2026-03-21": 0.25, "2026-03-22": 2.25}, "5": {...} },
  "dayTotals": { "2026-03-16": 0, ..., "2026-03-22": 4.25 }
}
```

**Note critiche sul parsing**:

1. **`grid` come Map con chiavi intere**: PHP serializza `[2 => [...]]` come `{"2": {...}}`. Il parsing usa `(gridRaw is Map) ? gridRaw.cast<String, dynamic>() : {}` per gestire il caso PHP di array vuoto `[]`.

2. **Grid valori numerici diretti**: ogni cella del grid contiene direttamente le ore come float (somma di tutte le entry per quel progetto+giorno), non un oggetto entry completo.

3. **Ore come stringa o numero**: Laravel può serializzare i campi `decimal` come `"2.25"` (string) o `2.25` (number). Il parsing gestisce entrambi:
   ```dart
   final ore = raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0.0;
   ```

4. **Cast dell'inner map**: `(grid[pId] is Map) ? (grid[pId] as Map).cast<String, dynamic>() : {}` per sicurezza del runtime.

---

## WeekState e WeekNotifier

**Path**: `lib/features/week/week_provider.dart`

### WeekState

```dart
class WeekState {
  final WeekSummary? summary;
  final DateTime settimanaCorrente;  // sempre il lunedì della settimana
  final bool loading;
  final String? errore;
}
```

### WeekNotifier

```dart
class WeekNotifier extends StateNotifier<WeekState> {
  // Inizializza con il lunedì della settimana corrente
  // d - (d.weekday - 1) giorni
  WeekNotifier(client) : super(WeekState(
    settimanaCorrente: _lunesDellaSettimana(DateTime.now())
  )) { carica(); }

  Future<void> carica() async {
    // GET /api/v1/me/timesheet/week?week=2026-03-16
    final summary = await _client.getTimesheetWeek(weekStart: state.settimanaCorrente);
    state = state.copyWith(summary: summary);
  }

  void settimanaPrec() {
    // -7 giorni, poi carica()
  }

  void settimanaSucc() {
    // +7 giorni, solo se non supera la settimana corrente
    final prossima = state.settimanaCorrente.add(Duration(days: 7));
    if (prossima.isAfter(DateTime.now())) return;
    ...
  }
}
```

Il provider viene **invalidato** dopo ogni salvataggio registrazione:
```dart
ref.invalidate(weekProvider);  // in timer_screen.dart
```

---

## WeekScreen

**Path**: `lib/features/week/week_screen.dart`

### Layout

```
┌─────────────────────────────────────────────────────┐
│  ←   17 mar – 23 mar                             →  │  ← navigazione settimana
│─────────────────────────────────────────────────────│
│ Progetto          Lun Mar Mer Gio Ven Sab Dom  Tot  │
│─────────────────────────────────────────────────────│
│ App Mobile Beta    -   -   -   -   -  2h  2h  4h   │
│ Consulenza GDPR    -   -   -   -   -   -  2h  2h   │
│ Manutenzione       -   -   -   -   -   -  0h  0h   │
│─────────────────────────────────────────────────────│
│ Totale             -   -   -   -   -  2h  4h  6h   │
└─────────────────────────────────────────────────────┘
```

Scrollabile sia verticalmente (molti progetti) che orizzontalmente (se la finestra fosse più stretta).

### Colonne

| Campo | Larghezza |
|-------|-----------|
| Nome progetto | 90 px |
| Ogni giorno (×7) | 44 px |
| Totale | 44 px |

Larghezza totale minima: 90 + 7×44 + 44 = 442 px. La finestra è 480 px — fitting senza scroll orizzontale nella maggior parte dei casi.

### Formattazione celle

```dart
String _fmt(int minuti) {
  if (minuti == 0) return '-';
  final h = minuti ~/ 60;
  final m = minuti % 60;
  return m == 0 ? '${h}h' : '${h}h${m}m';
}
```

### Navigazione settimana

- **Freccia sinistra**: sempre abilitata (nessun limite nel passato)
- **Freccia destra**: disabilitata se si è nella settimana corrente (`isSettimanaCorrente`)

```dart
final isSettimanaCorrente =
    !state.settimanaCorrente.add(Duration(days: 7)).isBefore(oggi);
```

---

## Endpoint API

```
GET /api/v1/me/timesheet/week?week=2026-03-16
Authorization: Bearer <token>

Response:
{
  "weekStart": "2026-03-16T00:00:00.000000Z",
  "weekEnd":   "2026-03-22T23:59:59.999999Z",
  "days":      ["2026-03-16", ..., "2026-03-22"],
  "projects":  [{ "id": 2, "name": "App Mobile Beta", ... }],
  "grid":      { "2": { "2026-03-22": 2.25 }, "5": { "2026-03-22": 1.75 } },
  "dayTotals": { "2026-03-16": 0, ..., "2026-03-22": 4.0 },
  "weekTotal": 4.0
}
```

**Nota**: il parametro `week` deve essere il lunedì della settimana in formato `YYYY-MM-DD`. Il backend calcola `endOfWeek(Sunday)` internamente.

**Nota**: il `grid` contiene valori float **sommati** per (progetto, giorno) — supporta più registrazioni sullo stesso progetto nello stesso giorno.
