import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/user_profile.dart';
import '../../core/utils/version_utils.dart';

/// Stato del check aggiornamenti.
enum UpdateStatus { idle, checking, upToDate, updateAvailable, downloading, error }

/// Stato del tab Info: profilo utente e stato aggiornamenti.
class InfoState {
  final UserProfile? profilo;
  final UpdateStatus updateStatus;
  final String? versione;
  final String? nuovaVersione;
  final String? dmgUrl;
  final double? downloadProgress;
  final String? errore;
  final String? serverUrl;

  const InfoState({
    this.profilo,
    this.updateStatus = UpdateStatus.idle,
    this.versione,
    this.nuovaVersione,
    this.dmgUrl,
    this.downloadProgress,
    this.errore,
    this.serverUrl,
  });

  InfoState copyWith({
    UserProfile? profilo,
    UpdateStatus? updateStatus,
    String? versione,
    String? nuovaVersione,
    String? dmgUrl,
    double? downloadProgress,
    String? errore,
    String? serverUrl,
    bool clearErrore = false,
    bool clearNuovaVersione = false,
    bool clearDmgUrl = false,
    bool clearProgress = false,
  }) {
    return InfoState(
      profilo: profilo ?? this.profilo,
      updateStatus: updateStatus ?? this.updateStatus,
      versione: versione ?? this.versione,
      nuovaVersione: clearNuovaVersione ? null : (nuovaVersione ?? this.nuovaVersione),
      dmgUrl: clearDmgUrl ? null : (dmgUrl ?? this.dmgUrl),
      downloadProgress: clearProgress ? null : (downloadProgress ?? this.downloadProgress),
      errore: clearErrore ? null : (errore ?? this.errore),
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }
}

/// Notifier per il tab Info: gestisce profilo utente e check aggiornamenti.
class InfoNotifier extends StateNotifier<InfoState> {
  final ApiClient? _client;
  bool _checkFatto = false;

  InfoNotifier(this._client) : super(const InfoState());

  /// Carica profilo + controlla versione. Idempotente (usa flag _checkFatto).
  Future<void> init() async {
    if (_checkFatto) return;
    _checkFatto = true;
    await _caricaProfilo();
    await _eseguiCheckUpdate();
  }

  /// Forza nuovo check GitHub (ignora _checkFatto).
  Future<void> checkUpdate() async {
    _checkFatto = true;
    await _eseguiCheckUpdate();
  }

  void aggiornaProgress(double progress) {
    state = state.copyWith(
      updateStatus: UpdateStatus.downloading,
      downloadProgress: progress,
    );
  }

  void impostaErrore(String msg) {
    state = state.copyWith(updateStatus: UpdateStatus.error, errore: msg);
  }

  Future<void> _caricaProfilo() async {
    try {
      if (_client == null) return;
      final profilo = await _client.getProfilo();
      final serverUrl = _client.baseUrl;
      state = state.copyWith(profilo: profilo, serverUrl: serverUrl);
    } catch (_) {
      // Profilo non disponibile: sezione Account mostrerà "Non disponibile"
    }
  }

  Future<void> _eseguiCheckUpdate() async {
    state = state.copyWith(
      updateStatus: UpdateStatus.checking,
      clearErrore: true,
    );
    try {
      final pkgInfo = await PackageInfo.fromPlatform();
      final installedVersion = pkgInfo.version;
      state = state.copyWith(versione: installedVersion);

      final response = await http
          .get(
            Uri.parse('https://api.github.com/repos/wtechdev/maelstrom_companion/releases/latest'),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 403 || response.statusCode == 429) {
        state = state.copyWith(
          updateStatus: UpdateStatus.error,
          errore: 'Limite richieste GitHub raggiunto. Riprova tra un\'ora.',
        );
        return;
      }

      if (response.statusCode != 200) {
        state = state.copyWith(
          updateStatus: UpdateStatus.error,
          errore: 'Impossibile controllare aggiornamenti (HTTP ${response.statusCode})',
        );
        return;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String;
      final latestVersion = tagName.replaceFirst('v', '');

      final assets = json['assets'] as List<dynamic>;
      final dmgAsset = assets.cast<Map<String, dynamic>>().firstWhere(
        (a) => (a['name'] as String).endsWith('.dmg'),
        orElse: () => {},
      );
      final dmgUrl = dmgAsset['browser_download_url'] as String?;

      if (isNewerVersion(installedVersion, latestVersion)) {
        state = state.copyWith(
          updateStatus: UpdateStatus.updateAvailable,
          nuovaVersione: latestVersion,
          dmgUrl: dmgUrl,
        );
      } else {
        state = state.copyWith(updateStatus: UpdateStatus.upToDate);
      }
    } catch (e) {
      state = state.copyWith(
        updateStatus: UpdateStatus.error,
        errore: 'Impossibile controllare aggiornamenti',
      );
    }
  }
}

final infoProvider = StateNotifierProvider<InfoNotifier, InfoState>(
  (ref) {
    final client = ref.watch(apiClientProvider).valueOrNull;
    return InfoNotifier(client);
  },
);
