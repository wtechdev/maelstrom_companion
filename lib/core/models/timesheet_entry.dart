/// Registrazione ore giornaliera dal backend.
/// Campi API: id, project{id,name}, data (date), ore (float), descrizione.
class TimesheetEntry {
  final int id;
  final String progetto;
  final DateTime data;
  final double ore;
  final String? descrizione;

  const TimesheetEntry({
    required this.id,
    required this.progetto,
    required this.data,
    required this.ore,
    this.descrizione,
  });

  int get minutiTotali => (ore * 60).round();

  String get durataFormattata {
    final h = minutiTotali ~/ 60;
    final m = minutiTotali % 60;
    return m > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${h}h';
  }

  String get orarioFormattato {
    // L'API restituisce ore giornaliere senza orario inizio/fine
    final h = ore.floor();
    final m = ((ore - h) * 60).round();
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  factory TimesheetEntry.fromJson(Map<String, dynamic> json) {
    final project = json['project'] as Map<String, dynamic>?;
    return TimesheetEntry(
      id: json['id'] as int,
      progetto: project?['name'] as String? ?? '-',
      data: DateTime.parse(json['data'] as String),
      ore: (json['ore'] as num).toDouble(),
      descrizione: json['descrizione'] as String?,
    );
  }
}
