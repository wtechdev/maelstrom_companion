import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/timesheet_entry.dart';

class TimesheetState {
  final List<TimesheetEntry> voci;
  final bool loading;
  final String? errore;

  const TimesheetState({this.voci = const [], this.loading = false, this.errore});

  int get totaleMinuti => voci.fold(0, (acc, e) => acc + e.minutiTotali);
  String get totaleFormattato {
    final ore = totaleMinuti ~/ 60;
    final min = totaleMinuti % 60;
    return '${ore}h ${min.toString().padLeft(2, '0')}m';
  }

  TimesheetState copyWith({List<TimesheetEntry>? voci, bool? loading, String? errore, bool clearErrore = false}) =>
      TimesheetState(
        voci: voci ?? this.voci,
        loading: loading ?? this.loading,
        errore: clearErrore ? null : (errore ?? this.errore),
      );
}

class TimesheetNotifier extends StateNotifier<TimesheetState> {
  final ApiClient _client;
  TimesheetNotifier(this._client) : super(const TimesheetState()) {
    carica();
  }

  Future<void> carica() async {
    state = state.copyWith(loading: true, clearErrore: true);
    try {
      final voci = await _client.getTimesheetOggi();
      state = state.copyWith(voci: voci, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, errore: 'Errore caricamento: $e');
    }
  }
}

final timesheetProvider = StateNotifierProvider<TimesheetNotifier, TimesheetState>((ref) {
  final client = ref.watch(apiClientProvider).valueOrNull;
  if (client == null) throw Exception('ApiClient non disponibile');
  return TimesheetNotifier(client);
});
