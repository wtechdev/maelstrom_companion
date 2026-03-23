# Spec: Tab "Info" con auto-update — Maelstrom Companion

**Data:** 2026-03-23
**Versione app corrente:** 1.0.1
**Scope:** Aggiunta quinto tab "Info" con informazioni utente/app e auto-update via GitHub Releases

---

## Obiettivo

Aggiungere un tab "Info" permanente in fondo alla navigation bar del companion app macOS. Il tab mostra:
- Informazioni sull'app (versione installata, stato aggiornamento)
- Dati dell'utente autenticato (nome completo, email, ruolo, struttura)
- URL del server configurato
- Meccanismo di auto-update via GitHub Releases + script bash

---

## Prerequisiti di sistema

L'app è distribuita **senza App Sandbox** (verificato: `macos/Runner/DebugProfile.entitlements` e `Release.entitlements` non includono `com.apple.security.app-sandbox`). L'esecuzione di script bash in `/tmp` via `dart:io Process` è quindi permessa dal sistema.

---

## Layout: Sezioni Distinte (layout C)

```
┌─────────────────────────────┐
│ [App]                       │
│  W  Maelstrom Companion     │
│     Versione 1.0.1    [badge]│
│  ──────────────────────     │
│  Controlla aggiornamenti    │
├─────────────────────────────┤
│ [Account]                   │
│  Mario Rossi                │
│  mario@demo.local           │
│  Ruolo: dipendente          │
│  Struttura: Azienda Demo A  │
├─────────────────────────────┤
│ [Server]                    │
│  http://localhost:8080      │
└─────────────────────────────┘
```

Tre sezioni con label uppercase (`App`, `Account`, `Server`), stile Settings-like. Sfondo usa `FrostedContainer` esistente (`lib/shared/widgets/frosted_container.dart`).

---

## Stati del badge aggiornamento

| # | Stato | Visual |
|---|-------|--------|
| 1 | Verifica in corso | Spinner blu circolante + "Controllo in corso..." |
| 2 | Aggiornato | Badge verde "✓ Aggiornato" |
| 3 | Nuova versione disponibile | Card arancione con versione + pulsante "Aggiorna" |
| 4 | Download in corso | Barra progresso blu + "L'app si riavvierà automaticamente" |
| 5 | Errore | Card rossa + link "Riprova" |

Il check avviene automaticamente all'apertura del tab (una sola volta per sessione), e manualmente tramite il link "Controlla aggiornamenti".

---

## Architettura

### Nuovi file

```
lib/features/info/
├── info_screen.dart         # UI con le 3 sezioni e i 5 stati (ConsumerStatefulWidget)
├── info_provider.dart       # StateNotifier per stato update
└── update_service.dart      # Download DMG + scrittura script bash

lib/core/models/
└── user_profile.dart        # Modello UserProfile (nome, cognome, email, ruolo, struttura)

lib/core/utils/
└── version_utils.dart       # isNewerVersion() — confronto semver, funzione pubblica testabile
```

### File modificati

| File | Modifica |
|------|----------|
| `lib/app_router.dart` | Aggiunge 5° `StatefulShellBranch` per `/home/info` |
| `lib/features/shell/home_shell.dart` | Aggiunge 5° tab con icona W-Tech |
| `lib/core/api/api_client.dart` | `getProfilo()` restituisce `UserProfile` tipizzato |
| `pubspec.yaml` | Aggiunge `package_info_plus: ^8.0.0` |

### Widget `InfoScreen`

`InfoScreen` deve estendere **`ConsumerStatefulWidget`** (non `ConsumerWidget`) per chiamare `init()` in `initState`.

### Dipendenze nuove

- **`package_info_plus`**: legge la versione installata dal `pubspec.yaml` a runtime (via `PackageInfo.fromPlatform()`)
- **GitHub Releases API** (no auth): `GET https://api.github.com/repos/wtechdev/maelstrom_companion/releases/latest` → campo `tag_name` (es. `v1.0.2`)

---

## Modello `UserProfile`

Schema API verificato da `UserResource.php`:

```json
{
  "data": {
    "uid": "...",
    "nome": "Mario",
    "cognome": "Rossi",
    "email": "mario@demo.local",
    "ruolo": "dipendente",
    "struttura": { "id": 1, "nome": "Azienda Demo A" }
  }
}
```

Il campo `struttura` è un oggetto `{id, nome}` o `null` se l'utente non ha strutture.

```dart
class UserProfile {
  final String nome;
  final String cognome;
  final String email;
  final String? ruolo;
  final String? struttura; // nome della struttura, nullable

  String get nomeCompleto => '$nome $cognome';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final dati = json['data'] as Map<String, dynamic>;
    final strutturaObj = dati['struttura'] as Map<String, dynamic>?;
    return UserProfile(
      nome: dati['nome'] as String,
      cognome: dati['cognome'] as String,
      email: dati['email'] as String,
      ruolo: dati['ruolo'] as String?,
      struttura: strutturaObj?['nome'] as String?,
    );
  }
}
```

---

## Provider: `InfoNotifier`

```dart
// Stato — immutabile con copyWith
class InfoState {
  final UserProfile? profilo;
  final UpdateStatus updateStatus;
  final String? versione;           // versione installata
  final String? nuovaVersione;      // versione GitHub disponibile (senza "v")
  final String? dmgUrl;             // URL download asset DMG
  final double? downloadProgress;   // 0.0–1.0 durante download
  final String? errore;

  InfoState copyWith({...});
}

enum UpdateStatus { idle, checking, upToDate, updateAvailable, downloading, error }

// StateNotifierProvider senza .autoDispose: persistente per tutta la sessione app.
// Il notifier non viene distrutto al cambio tab — sessione-idempotenza garantita.
final infoProvider = StateNotifierProvider<InfoNotifier, InfoState>(
  (ref) => InfoNotifier(ref),
);
```

**Metodi:**
- `init()` — carica profilo + controlla versione; idempotente (usa flag `_checkFatto`)
- `checkUpdate()` — forza nuovo check GitHub (ignora `_checkFatto`)
- `avviaAggiornamento()` — scarica DMG e lancia script

---

## Meccanismo Auto-Update

### Flusso

```
click "Aggiorna"
  → UpdateService.scaricaDmg(url, onProgress)
  → download DMG in /tmp/MaelstromCompanion-{version}.dmg
  → UpdateService.scriviScript(dmgPath, appInstallPath)
  → script scritto in /tmp/maelstrom_updater.sh (path sanitizzati)
  → Process.run('chmod', ['+x', '/tmp/maelstrom_updater.sh'])
  → Process.start('/tmp/maelstrom_updater.sh', [], runInShell: false)
  → exit(0)
```

`runInShell: false` e argomenti separati eliminano il rischio di shell injection. I path vengono passati come variabili di ambiente allo script, non interpolati nella stringa bash.

### Script bash (`/tmp/maelstrom_updater.sh`)

```bash
#!/bin/bash
# Variabili passate via environment (no interpolazione inline)
DMG_PATH="${MAELSTROM_DMG_PATH}"
APP_DEST="${MAELSTROM_APP_DEST}"

sleep 2

# Monta il DMG
MOUNT=$(hdiutil attach "$DMG_PATH" -nobrowse -quiet | tail -1 | awk '{print $NF}')

# Rimuove la versione esistente e copia con ditto (tool macOS per bundle)
rm -rf "$APP_DEST"
ditto "$MOUNT/Maelstrom Companion.app" "$APP_DEST"

# Smonta e rilancia
hdiutil detach "$MOUNT" -quiet
open "$APP_DEST"

# Pulizia
rm -f "$DMG_PATH"
rm -f "$0"
```

`ditto` gestisce correttamente i bundle macOS (preserva xattr, fork risorse, struttura). Sostituisce `cp -R` che può fallire con bundle in uso o lasciare lo stato parzialmente sovrascritto.

I valori `MAELSTROM_DMG_PATH` e `MAELSTROM_APP_DEST` sono impostati come environment variables su `Process.start`, non interpolati nello script generato.

### Determinazione `appInstallPath`

```dart
static String get appInstallPath {
  // Deriva il path dell'app in esecuzione da Platform.resolvedExecutable:
  // es. ".../Maelstrom Companion.app/Contents/MacOS/MaelstromCompanion"
  // risale di 3 livelli per ottenere il bundle .app
  final exe = Platform.resolvedExecutable;
  final parts = exe.split('/');
  // Rimuove "Contents/MacOS/<binary>" (3 segmenti)
  if (parts.length > 3) {
    return parts.sublist(0, parts.length - 3).join('/');
  }
  return '/Applications/Maelstrom Companion.app'; // fallback
}
```

Questo approccio funziona indipendentemente da dove l'utente ha installato l'app (`/Applications`, `~/Applications`, ecc.).

### URL DMG

Dalla risposta GitHub Releases: `assets[].browser_download_url` dove `assets[].name` termina con `.dmg`.

---

## Check Versione

```dart
// Versione installata
final pkgInfo = await PackageInfo.fromPlatform();
final installedVersion = pkgInfo.version; // es. "1.0.1"

// Versione GitHub (con timeout e gestione rate-limit)
final response = await http.get(
  Uri.parse('https://api.github.com/repos/wtechdev/maelstrom_companion/releases/latest'),
  headers: {'Accept': 'application/vnd.github+json'},
).timeout(const Duration(seconds: 10));

if (response.statusCode == 403 || response.statusCode == 429) {
  throw const GithubRateLimitException();
}

final tagName = json['tag_name'] as String; // es. "v1.0.2"
final latestVersion = tagName.replaceFirst('v', '');
```

### Confronto versioni (semver)

L'helper `isNewerVersion` è estratto in **`lib/core/utils/version_utils.dart`** come funzione top-level pubblica, testabile direttamente da `test/`:

```dart
// lib/core/utils/version_utils.dart
/// Restituisce true se [latest] è una versione maggiore di [installed].
/// Ignora i tag pre-release (es. "1.1.0-beta").
bool isNewerVersion(String installed, String latest) {
  if (latest.contains('-')) return false;

  final a = installed.split('.').map(int.parse).toList();
  final b = latest.split('.').map(int.parse).toList();

  for (var i = 0; i < b.length; i++) {
    final ai = i < a.length ? a[i] : 0;
    if (b[i] > ai) return true;
    if (b[i] < ai) return false;
  }
  return false;
}
```

---

## UI: `InfoScreen`

```dart
class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});
  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(infoProvider.notifier).init());
  }
  // ...
}
```

**Struttura widget:**

```
Padding
└─ SingleChildScrollView    ← per robustezza su finestre ridotte
   └─ Column
      ├─ _SectionLabel("App")
      ├─ _AppSection(state)      ← logo + versione + badge/stati update
      ├─ SizedBox(height: 12)
      ├─ _SectionLabel("Account")
      ├─ _AccountSection(profilo)
      ├─ SizedBox(height: 12)
      ├─ _SectionLabel("Server")
      └─ _ServerSection(baseUrl)
```

I widget `_*Section` sono privati a `info_screen.dart`. Nessuna astrazione prematura — tre widget privati con responsabilità chiara.

---

## Navigazione

**`app_router.dart`** — aggiunta branch:

```dart
StatefulShellBranch(routes: [
  GoRoute(path: '/home/info', builder: (ctx, s) => const InfoScreen()),
]),
```

**`home_shell.dart`** — aggiunta tab:

```dart
NavigationDestination(
  icon: WtechLogo(size: 20, colore: Colors.grey),
  selectedIcon: WtechLogo(size: 20, colore: theme.colorScheme.primary),
  label: 'Info',
),
```

Il widget `WtechLogo` esiste in `lib/shared/widgets/wtech_logo.dart`.

---

## Gestione Errori

| Scenario | Comportamento |
|----------|--------------|
| API `/me` irraggiungibile | Sezione Account vuota con testo "Non disponibile" |
| GitHub API timeout (>10s) | Stato `error`, link "Riprova" visibile |
| GitHub API 403/429 (rate limit) | Stato `error`, messaggio "Limite richieste GitHub raggiunto. Riprova tra un'ora." |
| Download DMG fallisce | Stato `error` con messaggio specifico |
| Script bash non eseguibile | Stato `error`, log console |

---

## Testing

I test vengono scritti **prima** dell'implementazione (TDD).

**Unit test — `UserProfile.fromJson`** (scritti per primi, con il modello):
- Parsing corretto con tutti i campi inclusa `struttura` come oggetto `{id, nome}`
- `struttura: null` → campo `struttura` del modello è `null`
- `nomeCompleto` concatena `nome` + `cognome` correttamente

**Unit test — `isNewerVersion`** (in `lib/core/utils/version_utils.dart`):
- `"1.0.1"` vs `"1.0.2"` → `true`
- `"1.0.1"` vs `"1.0.1"` → `false`
- `"1.0.1"` vs `"1.0.0"` → `false`
- `"1.0.1"` vs `"1.1.0-beta"` → `false` (pre-release ignorato)
- `"1.0.9"` vs `"1.0.10"` → `true` (confronto numerico, non lessicografico)

**Unit test — `UpdateService`:**
- Download con errore di rete → eccezione propagata correttamente
- Path DMG risultante segue formato `/tmp/MaelstromCompanion-{version}.dmg`
- Script generato contiene `MAELSTROM_DMG_PATH` e `MAELSTROM_APP_DEST` come variabili di ambiente, non path interpolati nella stringa script

**Unit test — `InfoNotifier`:**
- Stato iniziale è `idle`
- `init()` → transizione `checking` → `upToDate` quando versioni coincidono
- `init()` → transizione `checking` → `updateAvailable` quando GitHub è più recente
- Seconda chiamata a `init()` non ri-esegue il check (`_checkFatto` flag)
- `checkUpdate()` → forza nuovo check ignorando `_checkFatto`
- GitHub API timeout → stato `error`
- GitHub API 403 → stato `error` con messaggio rate-limit

**Widget test — `InfoScreen`:**
- Badge "Aggiornato" visibile con stato `upToDate`
- Card arancione e pulsante "Aggiorna" visibili con stato `updateAvailable`
- Spinner visibile con stato `checking`
- Barra progresso visibile con stato `downloading`
- Card rossa e "Riprova" visibili con stato `error`

---

## Sequenza di implementazione

1. Aggiunge `package_info_plus` a `pubspec.yaml` → `flutter pub get`
2. Crea `lib/core/utils/version_utils.dart` (vuoto, solo firma)
3. **[TDD]** Scrive test `UserProfile.fromJson` e `isNewerVersion` (RED)
4. Implementa `UserProfile` model + aggiorna `ApiClient.getProfilo()` + `version_utils.dart`
5. Verifica test al passo 3 passano (GREEN)
6. **[TDD]** Scrive test `UpdateService` e test `InfoNotifier` (RED)
7. Implementa `InfoNotifier` (`info_provider.dart`) + `UpdateService` (`update_service.dart`)
8. Verifica test al passo 6 passano (GREEN)
9. **[TDD]** Scrive widget test `InfoScreen` (RED)
10. Implementa `InfoScreen` (`info_screen.dart`) — `ConsumerStatefulWidget`
11. Aggiorna `app_router.dart` (5° branch) e `home_shell.dart` (5° tab)
12. Verifica widget test al passo 9 passano (GREEN)
13. Esegue tutti i test: `flutter test`
14. `flutter analyze` — zero warning
15. Verifica manuale con `flutter run -d macos`

---

## Fuori scope

- Notifiche push per nuovi aggiornamenti
- Changelog inline nell'app
- Rollback a versione precedente
- Update differenziali (patch)
- Firma DMG verificata a runtime (Gatekeeper lo gestisce)
- Notarizzazione automatica
