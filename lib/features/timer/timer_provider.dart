import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/timer_status.dart';
import '../../shared/tray/tray_manager_service.dart';

class TimerState {
  final TimerStatus status;
  final bool loading;
  final String? errore;

  const TimerState({
    required this.status,
    this.loading = false,
    this.errore,
  });

  TimerState copyWith({TimerStatus? status, bool? loading, String? errore, bool clearErrore = false}) =>
      TimerState(
        status: status ?? this.status,
        loading: loading ?? this.loading,
        errore: clearErrore ? null : (errore ?? this.errore),
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
    } catch (e) {
      state = state.copyWith(loading: false, errore: 'Impossibile avviare il timer.');
    }
  }

  Future<void> fermaTimer() async {
    state = state.copyWith(loading: true, clearErrore: true);
    try {
      await _client.stopTimer();
      _fermaTick();
      await TrayManagerService.aggiornaTitolo(null);
      state = state.copyWith(status: TimerStatus.inattivo(), loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, errore: 'Impossibile fermare il timer.');
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
