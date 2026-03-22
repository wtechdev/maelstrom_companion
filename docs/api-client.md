# API Client

## Panoramica

`ApiClient` è il punto di accesso unico a tutte le chiamate HTTP verso il backend Maelstrom. Gestisce autenticazione Bearer, encoding/decoding JSON e normalizzazione degli errori tramite `ApiException`.

---

## File coinvolti

| File | Responsabilità |
|------|---------------|
| `lib/core/api/api_client.dart` | Client HTTP con tutti gli endpoint |
| `lib/core/api/api_exception.dart` | Eccezione normalizzata per errori API |

---

## ApiClient

**Path**: `lib/core/api/api_client.dart`

### Costruzione

```dart
ApiClient({
  required String baseUrl,   // es. "http://localhost:8080"
  required String token,     // Bearer token
  http.Client? httpClient,   // iniettabile per test
})
```

Istanza costruita da `apiClientProvider` (Riverpod) leggendo url e token da `TokenStorage`.

### Header comuni

```dart
Map<String, String> get _headers => {
  'Authorization': 'Bearer $token',
  'Accept': 'application/json',
  'Content-Type': 'application/json',
};
```

### Metodi privati

| Metodo | Descrizione |
|--------|-------------|
| `_get(path)` | GET → `_parseResponse` |
| `_post(path, body?)` | POST con body JSON → `_parseResponse` |
| `_parseResponse(response)` | 2xx → `jsonDecode`; altrimenti → `ApiException` |

### Parsing risposta

```dart
Map<String, dynamic> _parseResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  // Errore: estrae 'message' dal body se disponibile
  String msg = 'Errore ${response.statusCode}';
  try {
    msg = (jsonDecode(response.body))['message'] ?? msg;
  } catch (_) {}
  throw ApiException(statusCode: response.statusCode, message: msg);
}
```

---

## Endpoint implementati

### Autenticazione (statico, no Bearer)

```dart
static Future<Map<String, dynamic>> login({
  required String baseUrl,
  required String email,
  required String password,
})
```

```
POST /api/v1/companion/login
Body: { "email": "...", "password": "..." }
Response: { "data": { "token": "...", "user": {...} } }
```

---

### Profilo

```dart
Future<Map<String, dynamic>> getProfilo()
```

```
GET /api/v1/me
```

---

### Progetti

```dart
Future<List<Project>> getProjects()
```

```
GET /api/v1/me/projects
Response: { "data": [ {id, name, ...} ] }
```

Parsing: `data['data'] as List<dynamic>`

---

### Timesheet oggi

```dart
Future<List<TimesheetEntry>> getTimesheetOggi()
```

```
GET /api/v1/me/timesheet?da=YYYY-MM-DD&a=YYYY-MM-DD
(stessa data per filtrare solo oggi)
Response: { "data": [ TimesheetEntry... ], "meta": {...} }
```

Parsing: `data['data'] as List<dynamic>`

---

### Timesheet settimana

```dart
Future<WeekSummary> getTimesheetWeek({DateTime? weekStart})
```

```
GET /api/v1/me/timesheet/week
GET /api/v1/me/timesheet/week?week=2026-03-16

Response: { weekStart, weekEnd, days, projects, grid, dayTotals, weekTotal }
```

Il backend restituisce i dati **direttamente** (senza wrapper `data`). Usare `WeekSummary.fromJson(data)` direttamente.

---

### Timer — status

```dart
Future<TimerStatus> getTimerStatus()
```

```
GET /api/v1/me/timer/status
Response (inattivo): { "active": false }
Response (attivo):   { "active": true, "timer": { "project_id": 2, "started_at": "..." } }
```

Parsing:
```dart
final payload = data['data'] as Map<String, dynamic>? ?? data;
return TimerStatus.fromJson(payload);
```

---

### Timer — avvia

```dart
Future<TimerStatus> startTimer(int projectId)
```

```
POST /api/v1/me/timer/start
Body: { "project_id": 2 }
Response: { "success": true, "timer": { "project_id": 2, "started_at": "2026-03-22T09:00:00Z" } }
```

Costruisce `TimerStatus` manualmente (la risposta non ha il campo `active`):
```dart
return TimerStatus(
  attivo: true,
  progettoId: timerMap?['project_id'] as int?,
  iniziato: timerMap?['started_at'] != null
      ? DateTime.parse(timerMap!['started_at'] as String)
      : DateTime.now(),
);
```

---

### Timer — ferma

```dart
Future<PendingTimerEntry> stopTimer({String? progettoNome})
```

```
POST /api/v1/me/timer/stop
Response: { "project_id": 2, "ore": 1.5, "started_at": "...", "stopped_at": "..." }
```

**Nota**: il backend usa la Laravel Cache per memorizzare il timer. `stopTimer` non crea una `TimeEntry` — la cancella dalla cache e restituisce i dati per la conferma.

---

### Salva registrazione

```dart
Future<void> salvaTimeEntry({
  required int projectId,
  required double ore,
  required DateTime data,
  required String tipoAttivita,
  String? descrizione,
})
```

```
POST /api/v1/me/timesheet
Body: {
  "project_id": 2,
  "data": "2026-03-22",
  "ore": 1.5,
  "tipo_attivita": "sviluppo",
  "descrizione": "..."   (omesso se null o vuoto)
}
Response: { "data": { ...TimeEntry... } }
```

La data viene formattata come `YYYY-MM-DD` con zero-padding esplicito.

---

## ApiException

**Path**: `lib/core/api/api_exception.dart`

```dart
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
```

I notifier Riverpod catturano `ApiException` separatamente dagli errori generici per esporre messaggi utente-friendly:

```dart
on ApiException catch (e) {
  state = state.copyWith(errore: e.message);
} catch (e) {
  state = state.copyWith(errore: 'Errore generico.');
}
```

---

## Compatibilità API

Il client gestisce alcune variazioni nel formato delle risposte backend:

| Problema | Soluzione |
|----------|-----------|
| `ore` come stringa (`"2.25"`) o numero (`2.25`) | `raw is num ? raw.toDouble() : double.tryParse(...)` |
| Risposta `timer/status` con o senza wrapper `data` | `data['data'] ?? data` |
| Grid settimana con array vuoto `[]` invece di oggetto `{}` | `gridRaw is Map ? gridRaw.cast<...>() : {}` |
| `startTimer` senza campo `active` | Costruisce `TimerStatus` direttamente con `attivo: true` |
| `started_at` annidato in `json['timer']` | `timerMap?['started_at'] ?? json['started_at']` |
