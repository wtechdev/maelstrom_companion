import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/week_summary.dart';

class WeekState {
  final WeekSummary? summary;
  final DateTime settimanaCorrente;
  final bool loading;
  final String? errore;

  WeekState({
    this.summary,
    required this.settimanaCorrente,
    this.loading = false,
    this.errore,
  });

  WeekState copyWith({
    WeekSummary? summary,
    DateTime? settimanaCorrente,
    bool? loading,
    String? errore,
    bool clearErrore = false,
  }) =>
      WeekState(
        summary: summary ?? this.summary,
        settimanaCorrente: settimanaCorrente ?? this.settimanaCorrente,
        loading: loading ?? this.loading,
        errore: clearErrore ? null : (errore ?? this.errore),
      );
}

DateTime _lunesDellaSettimana(DateTime d) =>
    d.subtract(Duration(days: d.weekday - 1));

class WeekNotifier extends StateNotifier<WeekState> {
  final ApiClient _client;

  WeekNotifier(this._client)
      : super(WeekState(
            settimanaCorrente: _lunesDellaSettimana(DateTime.now()))) {
    carica();
  }

  Future<void> carica() async {
    state = state.copyWith(loading: true, clearErrore: true);
    try {
      final summary =
          await _client.getTimesheetWeek(weekStart: state.settimanaCorrente);
      state = state.copyWith(summary: summary, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, errore: 'Errore caricamento: $e');
    }
  }

  void settimanaPrec() {
    state = state.copyWith(
        settimanaCorrente:
            state.settimanaCorrente.subtract(const Duration(days: 7)));
    carica();
  }

  void settimanaSucc() {
    final prossima =
        state.settimanaCorrente.add(const Duration(days: 7));
    if (prossima.isAfter(DateTime.now())) return;
    state = state.copyWith(settimanaCorrente: prossima);
    carica();
  }
}

final weekProvider =
    StateNotifierProvider<WeekNotifier, WeekState>((ref) {
  final client = ref.watch(apiClientProvider).valueOrNull;
  if (client == null) throw Exception('ApiClient non disponibile');
  return WeekNotifier(client);
});
