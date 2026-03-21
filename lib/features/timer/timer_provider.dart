import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/pending_timer_entry.dart';
import '../../core/models/timer_status.dart';
import '../../shared/tray/tray_manager_service.dart';

class TimerState {
  final TimerStatus status;
  final bool loading;
  final String? errore;
  final PendingTimerEntry? pendingEntry;

  const TimerState({
    required this.status,
    this.loading = false,
    this.errore,
    this.pendingEntry,
  });

  TimerState copyWith({
    TimerStatus? status,
    bool? loading,
    String? errore,
    bool clearErrore = false,
    PendingTimerEntry? pendingEntry,
    bool clearPending = false,
  }) =>
      TimerState(
        status: status ?? this.status,
        loading: loading ?? this.loading,
        errore: clearErrore ? null : (errore ?? this.errore),
        pendingEntry: clearPending ? null : (pendingEntry ?? this.pendingEntry),
      );
}

class TimerNotifier extends StateNotifier<TimerState> {
  final ApiClient _client;
  Timer? _tickTimer;

  TimerNotifier(this._client) : super(TimerState(status: TimerStatus.inattivo())) {
    carica();
  }

  Future<void> carica() async {
    state = state.copyWith(loading: true, clearErrore: true);
    try {
      final status = await _client.getTimerStatus();
      state = state.copyWith(status: status, loading: false);
      if (status.attivo) _avviaTick();
    } catch (e) {
      state = state.copyWith(loading: false, errore: 'Errore caricamento: $e');
    }
  }

  Future<void> avviaTimer(int projectId) async {
    state = state.copyWith(loading: true, clearErrore: true);
    try {
      final nuovoStatus = await _client.startTimer(projectId);
      state = state.copyWith(status: nuovoStatus, loading: false);
      _avviaTick();
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errore: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, errore: 'Impossibile avviare il timer.');
    }
  }

  Future<void> fermaTimer() async {
    state = state.copyWith(loading: true, clearErrore: true);
    try {
      final pending = await _client.stopTimer(
        progettoNome: state.status.progettoNome,
      );
      _fermaTick();
      await TrayManagerService.aggiornaTitolo(null);
      state = state.copyWith(
        status: TimerStatus.inattivo(),
        loading: false,
        pendingEntry: pending,
      );
    } catch (e) {
      state = state.copyWith(loading: false, errore: 'Impossibile fermare il timer.');
    }
  }

  Future<void> confermaSalvataggio({
    required TipoAttivita tipoAttivita,
    String? descrizione,
  }) async {
    final pending = state.pendingEntry;
    if (pending == null) return;
    state = state.copyWith(loading: true, clearErrore: true);
    try {
      await _client.salvaTimeEntry(
        projectId: pending.projectId,
        ore: pending.ore,
        data: DateTime.now(), // data di registrazione, non di avvio
        tipoAttivita: tipoAttivita.value,
        descrizione: descrizione,
      );
      state = state.copyWith(loading: false, clearPending: true);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errore: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, errore: 'Impossibile salvare la registrazione.');
    }
  }

  void annullaSalvataggio() {
    state = state.copyWith(clearPending: true, clearErrore: true);
  }

  Future<void> registraOreManuale({
    required int projectId,
    required double ore,
    required TipoAttivita tipoAttivita,
    String? descrizione,
  }) async {
    state = state.copyWith(loading: true, clearErrore: true);
    try {
      await _client.salvaTimeEntry(
        projectId: projectId,
        ore: ore,
        data: DateTime.now(),
        tipoAttivita: tipoAttivita.value,
        descrizione: descrizione,
      );
      state = state.copyWith(loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errore: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, errore: 'Impossibile salvare la registrazione.');
    }
  }

  void _avviaTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.status.attivo) {
        TrayManagerService.aggiornaTitolo('● ${state.status.elapsedFormattato}');
        state = state.copyWith(status: state.status);
      }
    });
  }

  void _fermaTick() => _tickTimer?.cancel();

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final client = ref.watch(apiClientProvider).valueOrNull;
  if (client == null) throw Exception('ApiClient non disponibile');
  return TimerNotifier(client);
});
