// Struttura API week:
// { weekStart, weekEnd, days:[date...], projects:[{id,name}],
//   grid:{project_id:{date:ore_float}}, dayTotals:{date:ore}, weekTotal }

class WeekProjectRow {
  final String progetto;
  final List<int> minutiPerGiorno; // lun-dom (7 elementi)
  final int totaleMinuti;

  const WeekProjectRow({
    required this.progetto,
    required this.minutiPerGiorno,
    required this.totaleMinuti,
  });
}

class WeekSummary {
  final DateTime inizioSettimana;
  final DateTime fineSettimana;
  final List<WeekProjectRow> righe;
  final List<int> totaliGiornalieri; // minuti per giorno (7 elementi)

  const WeekSummary({
    required this.inizioSettimana,
    required this.fineSettimana,
    required this.righe,
    required this.totaliGiornalieri,
  });

  factory WeekSummary.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List<dynamic>).map((d) => d as String).toList();
    final projects = json['projects'] as List<dynamic>;
    // PHP serializza array associativi vuoti come [] — gestiamo entrambi i casi
    final gridRaw = json['grid'];
    final grid = (gridRaw is Map) ? gridRaw.cast<String, dynamic>() : <String, dynamic>{};
    final dayTotalsRaw = json['dayTotals'];
    final dayTotals = (dayTotalsRaw is Map) ? dayTotalsRaw.cast<String, dynamic>() : <String, dynamic>{};

    final righe = projects.map((p) {
      final pMap = p as Map<String, dynamic>;
      final pId = pMap['id'].toString();
      final projGrid = (grid[pId] is Map) ? (grid[pId] as Map).cast<String, dynamic>() : <String, dynamic>{};
      final minutiPerGiorno = days.map((d) {
        final raw = projGrid[d];
        if (raw == null) return 0;
        final ore = raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0.0;
        return (ore * 60).round();
      }).toList();
      final totale = minutiPerGiorno.fold(0, (a, b) => a + b);
      return WeekProjectRow(
        progetto: pMap['name'] as String,
        minutiPerGiorno: minutiPerGiorno,
        totaleMinuti: totale,
      );
    }).toList();

    final totaliGiornalieri = days.map((d) {
      final raw = dayTotals[d];
      final ore = raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '') ?? 0.0;
      return (ore * 60).round();
    }).toList();

    return WeekSummary(
      inizioSettimana: DateTime.parse(json['weekStart'].toString()),
      fineSettimana: DateTime.parse(json['weekEnd'].toString()),
      righe: righe,
      totaliGiornalieri: totaliGiornalieri,
    );
  }
}
