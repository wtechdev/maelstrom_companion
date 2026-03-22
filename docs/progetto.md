# Selezione Progetto

## Panoramica

La `ProjectsScreen` è la schermata predefinita al login. Mostra la lista dei progetti disponibili per l'utente autenticato e permette di selezionare il progetto attivo su cui avviare il timer o registrare ore.

---

## File coinvolti

| File | Responsabilità |
|------|---------------|
| `lib/features/projects/projects_screen.dart` | UI lista progetti + selezione |
| `lib/core/providers/selected_project_provider.dart` | Stato globale progetto selezionato |
| `lib/core/models/project.dart` | Modello dati progetto |

---

## Modello Project

**Path**: `lib/core/models/project.dart`

```dart
class Project {
  final int id;
  final String nome;

  factory Project.fromJson(Map<String, dynamic> json) {
    // Gestisce sia 'name' che 'nome' come chiave API
    return Project(
      id: json['id'] as int,
      nome: json['name'] as String? ?? json['nome'] as String,
    );
  }
}
```

---

## selectedProjectProvider

**Path**: `lib/core/providers/selected_project_provider.dart`

```dart
final selectedProjectProvider = StateProvider<Project?>((ref) => null);
```

Provider globale condiviso tra:
- `ProjectsScreen` — scrittura (selezione)
- `TimerScreen` — lettura (mostra il progetto, avvia timer)

---

## ProjectsScreen

**Path**: `lib/features/projects/projects_screen.dart`

### Provider locale

```dart
final _projectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final client = await ref.watch(apiClientProvider.future);
  if (client == null) return [];
  return client.getProjects();
});
```

Chiama `GET /api/v1/me/projects` — restituisce i progetti a cui l'utente è assegnato (come membro, responsabile o tramite team).

### UI

```
┌─────────────────────────────┐
│ Progetto attivo             │
│ Seleziona il progetto       │
│─────────────────────────────│
│ ○  App Mobile Beta          │
│─────────────────────────────│
│ ●  Consulenza GDPR Acme     │  ← selezionato
│─────────────────────────────│
│ ○  Manutenzione Sistemi Gamma│
└─────────────────────────────┘
```

- **Spinner** durante il caricamento
- **Errore** con pulsante "Riprova" (richiama `_projectsProvider`)
- **Lista** con `ListView.separated`: ogni voce ha un radio button (filled/outlined) e il nome del progetto
- Il progetto attualmente selezionato è evidenziato con colore `primary`

### Interazione

Al tap su un progetto:
1. `ref.read(selectedProjectProvider.notifier).state = project`
2. `context.go('/home/timer')` — naviga automaticamente alla tab Timer

---

## Endpoint API

```
GET /api/v1/me/projects
Authorization: Bearer <token>

Response:
{
  "data": [
    { "id": 2, "name": "App Mobile Beta", ... },
    { "id": 5, "name": "Consulenza GDPR Acme", ... }
  ]
}
```

Il parsing usa `data['data'] as List<dynamic>`.
