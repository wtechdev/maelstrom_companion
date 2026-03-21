import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'week_provider.dart';

class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  static const _giorniShort = [
    'Lun',
    'Mar',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom'
  ];

  String _fmt(int minuti) {
    if (minuti == 0) return '-';
    final ore = minuti ~/ 60;
    final min = minuti % 60;
    return min == 0 ? '${ore}h' : '${ore}h${min}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weekProvider);
    final notifier = ref.read(weekProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    final oggi = DateTime.now();
    final isSettimanaCorrente =
        !state.settimanaCorrente.add(const Duration(days: 7)).isBefore(oggi);

    final inizioFmt =
        DateFormat('d MMM', 'it').format(state.settimanaCorrente);
    final fineFmt = DateFormat('d MMM', 'it')
        .format(state.settimanaCorrente.add(const Duration(days: 6)));
    final rangeLabel = '$inizioFmt – $fineFmt';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Column(
          children: [
            // Header navigazione settimana
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: state.loading ? null : notifier.settimanaPrec,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Expanded(
                    child: Text(
                      rangeLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isSettimanaCorrente
                          ? cs.onSurface.withValues(alpha: 0.3)
                          : null,
                    ),
                    onPressed: (state.loading || isSettimanaCorrente)
                        ? null
                        : notifier.settimanaSucc,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Contenuto
            Expanded(
              child: state.loading && state.summary == null
                  ? const Center(child: CircularProgressIndicator())
                  : state.errore != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  color: cs.error, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                state.errore!,
                                style:
                                    TextStyle(color: cs.error, fontSize: 12),
                              ),
                              TextButton(
                                onPressed: notifier.carica,
                                child: const Text('Riprova'),
                              ),
                            ],
                          ),
                        )
                      : state.summary == null
                          ? const SizedBox.shrink()
                          : _Griglia(
                              summary: state.summary!,
                              fmt: _fmt,
                              cs: cs,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Griglia extends StatelessWidget {
  final dynamic summary; // WeekSummary
  final String Function(int) fmt;
  final ColorScheme cs;

  const _Griglia({
    required this.summary,
    required this.fmt,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    const double colW = 44;
    const double progettoW = 90;
    final giorni = WeekScreen._giorniShort; // lun-dom

    final headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: cs.onSurface.withValues(alpha: 0.6),
    );
    const cellStyle = TextStyle(fontSize: 11);
    final totaleStyle = TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intestazione colonne
            Row(
              children: [
                SizedBox(
                  width: progettoW,
                  child: Text(
                    'Progetto',
                    style: headerStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final g in giorni)
                  SizedBox(
                    width: colW,
                    child: Text(g,
                        style: headerStyle, textAlign: TextAlign.center),
                  ),
                SizedBox(
                  width: colW,
                  child: Text('Tot',
                      style: headerStyle, textAlign: TextAlign.center),
                ),
              ],
            ),
            Divider(
                height: 12,
                color: cs.outlineVariant.withValues(alpha: 0.5)),
            // Righe progetti
            for (final riga in summary.righe) ...[
              Row(
                children: [
                  SizedBox(
                    width: progettoW,
                    child: Text(
                      riga.progetto,
                      style: cellStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (var i = 0; i < 7; i++)
                    SizedBox(
                      width: colW,
                      child: Text(
                        i < riga.minutiPerGiorno.length
                            ? fmt(riga.minutiPerGiorno[i])
                            : '-',
                        style: cellStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: colW,
                    child: Text(
                      fmt(riga.totaleMinuti),
                      style: totaleStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            // Riga totali
            if (summary.righe.isNotEmpty) ...[
              Divider(
                  height: 12,
                  color: cs.outlineVariant.withValues(alpha: 0.5)),
              Row(
                children: [
                  SizedBox(
                    width: progettoW,
                    child: const Text(
                      'Totale',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  for (var i = 0; i < 7; i++)
                    SizedBox(
                      width: colW,
                      child: Text(
                        i < summary.totaliGiornalieri.length
                            ? fmt(summary.totaliGiornalieri[i])
                            : '-',
                        style: totaleStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: colW,
                    child: Text(
                      fmt(summary.totaliGiornalieri
                          .fold(0, (a, b) => a + b)),
                      style: totaleStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
