# Autenticazione — Setup e Credenziali

## Panoramica

Al primo avvio, l'app mostra la `SetupScreen` dove l'utente inserisce email e password. Le credenziali vengono verificate contro il backend e il token risultante viene salvato localmente. Agli avvii successivi, il token viene letto automaticamente e l'utente viene portato direttamente alla schermata principale.

---

## File coinvolti

| File | Responsabilità |
|------|---------------|
| `lib/features/setup/setup_screen.dart` | UI login + dialog configurazione server |
| `lib/core/auth/token_storage.dart` | Lettura/scrittura credenziali su file JSON |
| `lib/core/auth/auth_provider.dart` | Provider Riverpod per stato auth e ApiClient |

---

## TokenStorage

**Path**: `lib/core/auth/token_storage.dart`

Salva le credenziali in un file JSON nella directory Application Support di macOS:

```
~/Library/Application Support/com.example.maelstromCompanion/maelstrom_credentials.json
```

### Struttura file JSON

```json
{
  "url": "http://localhost:8080",
  "token": "abc123..."
}
```

### API

| Metodo | Descrizione |
|--------|-------------|
| `getUrl()` | Legge l'URL base del backend |
| `getToken()` | Legge il Bearer token |
| `salva(url, token)` | Scrive url + token (trimma spazi, rimuove `/` finale dall'URL) |
| `haCredenziali()` | `true` se sia url che token sono presenti e non vuoti |
| `cancella()` | Elimina il file (logout) |

Gli errori di I/O sono catturati silenziosamente con `debugPrint`.

---

## Provider (auth_provider.dart)

```dart
// Singleton TokenStorage
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

// Verifica se l'utente è autenticato (bool)
final authStateProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(tokenStorageProvider);
  return storage.haCredenziali();
});

// Costruisce il client HTTP se le credenziali sono disponibili
final apiClientProvider = FutureProvider<ApiClient?>((ref) async {
  final storage = ref.watch(tokenStorageProvider);
  final url = await storage.getUrl();
  final token = await storage.getToken();
  if (url == null || token == null) return null;
  return ApiClient(baseUrl: url, token: token);
});
```

`authStateProvider` è osservato da `app_router.dart` per il redirect automatico:
- Se `false` → `/setup`
- Se `true` → `/home/projects`

---

## SetupScreen

**Path**: `lib/features/setup/setup_screen.dart`

### Stato interno

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `_emailController` | `TextEditingController` | Input email |
| `_passwordController` | `TextEditingController` | Input password |
| `_urlController` | `TextEditingController` | URL backend (nascosto nel dialog) |
| `_loading` | `bool` | Mostra spinner durante login |
| `_errore` | `String?` | Messaggio di errore |
| `_passwordVisible` | `bool` | Toggle visibilità password |

### Ciclo di vita

```
initState()
  └─ _caricaUrlSalvato()
      └─ storage.getUrl() → _urlController.text = url ?? 'http://localhost:8080'
```

### Flusso di login (_connetti)

```
1. Valida form (email non vuota, password non vuota)
2. ApiClient.login(url, email, password)
   → POST /api/v1/companion/login
   → Risposta: { data: { token: "..." } }
3. storage.salva(url, token)
4. ref.invalidate(tokenStorageProvider)
5. ref.invalidate(authStateProvider)
6. ref.invalidate(apiClientProvider)
7. await ref.read(authStateProvider.future)  ← attende la rivalutazione
8. context.go('/home/projects')
```

Il punto 7 è critico: senza `await`, la navigazione potrebbe avvenire prima che `authStateProvider` si aggiorni, causando un redirect immediato a `/setup`.

### Gestione errori

| Condizione | Messaggio mostrato |
|------------|-------------------|
| `ApiException` 401 | "Email o password non validi." |
| `ApiException` 403 | "Utente non associato ad una struttura." |
| Altra `ApiException` | "Errore: {message}" |
| Errore di rete | "Impossibile raggiungere il server. Verifica URL e connessione." |

### UI

```
┌─────────────────────────────┐  ← 28px clearance traffic lights
│  [gear icon]                │  ← top-right, apre dialog URL
│                             │
│      [W-Tech Logo]          │  ← centrato, 64px
│                             │
│   Email: [_____________]    │
│   Password: [__________]    │
│                             │
│   [errore in rosso]         │
│                             │
│   [    ACCEDI    ]          │  ← 48px height, fontSize 15
└─────────────────────────────┘
```

### Dialog configurazione server (_ServerDialog)

Accessibile dall'icona ingranaggio (top-right). Mostra un `AlertDialog` con un campo TextField per modificare l'URL del backend. Cambiare l'URL non invalida il token esistente — si applica solo al prossimo login.

---

## Logout

Non è disponibile un pulsante di logout esplicito nella UI attuale. Per disconnettersi è necessario:
1. Eliminare manualmente `maelstrom_credentials.json` dalla Application Support
2. Oppure implementare `TokenStorage.cancella()` + `ref.invalidate(authStateProvider)`
