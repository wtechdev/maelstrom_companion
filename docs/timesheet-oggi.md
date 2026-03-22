# Timesheet — Vista Oggi

## Panoramica

La tab "Oggi" mostra tutte le registrazioni ore dell'utente per la giornata corrente, con totale ore in testa. Supporta il pull-to-refresh per aggiornare manualmente i dati.

---

## File coinvolti

| File | Responsabilità |
|------|---------------|
| `lib/features/timesheet/timesheet_screen.dart` | UI lista registrazioni + header totale |
| `lib/features/timesheet/timesheet_provider.dart` | StateNotifier + caricamento dati |
| `lib/core/models/timesheet_entry.dart` | Modello singola registrazione |
| `lib/shared/widgets/entry_tile.dart` | Widget di visualizzazione singola voce |

---

## TimesheetEntry

**Path**: `lib/core/models/timesheet_entry.dart`

```dart
class TimesheetEntry {
  final int id;
  final String progetto;     // estratto da project.name
  final DateTime data;
  final double ore;          // gestisce int, double e string (decimal Laravel)
  final String? descrizione;

  int get minutiTotali => (ore * 60).round();

  String get durataFormattata {
    final h = ore.floor();
    final m = ((ore - h) * 60).round();
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
```

Il parsing di `ore` gestisce le varianti di serializzazione Laravel:
```dart
ore: json['ore'] is num
    ? (json['ore'] as num).toDouble()
    : double.tryParse(json['ore']?.toString() ?? '') ?? 0.0,
```

---

## TimesheetState e TimesheetNotifier

**Path**: `lib/features/timesheet/timesheet_provider.dart`

### TimesheetState

```dart
class TimesheetState {
  final List<TimesheetEntry> voci;
  final bool loading;
  final String? errore;

  int get totaleMinuti => voci.fold(0, (sum, e) => sum + e.minutiTotali);

  String get totaleFormattato {
    final h = totaleMinuti ~/ 60;
    final m = totaleMinuti % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
```

### TimesheetNotifier

```dart
class TimesheetNotifier extends StateNotifier<TimesheetState> {
  Future<void> carica() async {
    // GET /api/v1/me/timesheet?da=YYYY-MM-DD&a=YYYY-MM-DD
    // (stesso giorno per filtrare solo oggi)
    final voci = await _client.getTimesheetOggi();
    state = state.copyWith(voci: voci, loading: false);
  }
}
```

Il provider viene **invalidato automaticamente** dopo ogni salvataggio registrazione (timer o manuale), forzando il ricaricamento:

```dart
// In timer_screen.dart dopo salvataggio
ref.invalidate(timesheetProvider);
```

---

## TimesheetScreen

**Path**: `lib/features/timesheet/timesheet_screen.dart`

### Layout

```
┌─────────────────────────────┐
│ Oggi                        │
│ domenica 22 marzo 2026      │
│                    [4h 15m] │  ← totale giornaliero
│─────────────────────────────│
│ App Mobile Beta             │
│ 09:00               2h 15m  │
│─────────────────────────────│
│ Consulenza GDPR Acme        │
│ 11:30               1h 45m  │
│─────────────────────────────│
│ Manutenzione Sistemi Gamma  │
│ 14:00               0h 15m  │
└─────────────────────────────┘
```

Utilizza `CustomScrollView` con `RefreshIndicator` per il pull-to-refresh.

### Stati

| Stato | Visualizzazione |
|-------|----------------|
| `loading && voci.isEmpty` | Spinner centrato |
| `errore != null` | Icona errore + messaggio + pulsante "Riprova" |
| `voci.isEmpty` | Icona orologio + "Nessuna registrazione oggi" |
| `voci.isNotEmpty` | Lista `SliverList.separated` con `EntryTile` |

---

## EntryTile

**Path**: `lib/shared/widgets/entry_tile.dart`

Widget semplice per visualizzare una singola registrazione:

```
Row:
  Expanded:
    Text(entry.progetto, fontSize: 13)
    Text(entry.orarioFormattato, fontSize: 11, muted)
  Text(entry.durataFormattata, fontSize: 13, primary, bold)
```

---

## Endpoint API

```
GET /api/v1/me/timesheet?da=2026-03-22&a=2026-03-22
Authorization: Bearer <token>

Response:
{
  "data": [
    {
      "id": 231,
      "project": { "id": 2, "name": "App Mobile Beta" },
      "data": "2026-03-22",
      "ore": "2.25",
      "descrizione": "...",
      "tipo_attivita": "sviluppo",
      "stato": "registrata"
    }
  ],
  "meta": { "total": 3, ... }
}
```

Il campo `ore` può essere un numero o una stringa decimale (dipende dalla versione Laravel/configurazione JSON).
