# Changelog — feature/info-tab

## [Unreleased]

### Added
- Quinto tab "Info" nella navigation bar con icona W-Tech brandmark
- Sezione **App**: versione installata, stato aggiornamenti con 5 stati (checking, upToDate, updateAvailable, downloading, error)
- Sezione **Account**: nome completo, email, ruolo e struttura dell'utente autenticato
- Sezione **Server**: URL del server configurato
- Check automatico aggiornamenti all'apertura del tab (una volta per sessione) via GitHub Releases API
- Check manuale aggiornamenti tramite link "Controlla aggiornamenti"
- Auto-update: download DMG + script bash in `/tmp` con path come env-vars (no shell injection)
- Modello `UserProfile` con factory `fromJson` e getter `nomeCompleto`
- Utility `isNewerVersion()` per confronto semver numerico (ignora pre-release)
- `UpdateService` con `scaricaDmg`, `avviaAggiornamento` e `generaScript`
- `package_info_plus` per lettura versione installata a runtime

### Fixed
- HTTP 404 da GitHub Releases (repo senza release o privato) trattato come "Aggiornato" invece di errore
- Layout badge errore spostato sotto la Row per evitare il wrapping del titolo
