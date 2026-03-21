/// Dati restituiti da stopTimer: timer fermato ma non ancora salvato come TimeEntry.
class PendingTimerEntry {
  final int projectId;
  final String? progettoNome;
  final double ore;
  final DateTime startedAt;
  final DateTime stoppedAt;

  const PendingTimerEntry({
    required this.projectId,
    this.progettoNome,
    required this.ore,
    required this.startedAt,
    required this.stoppedAt,
  });

  factory PendingTimerEntry.fromJson(Map<String, dynamic> json, {String? progettoNome}) {
    return PendingTimerEntry(
      projectId: json['project_id'] as int,
      progettoNome: progettoNome,
      ore: (json['ore'] as num).toDouble(),
      startedAt: DateTime.parse(json['started_at'] as String),
      stoppedAt: DateTime.parse(json['stopped_at'] as String),
    );
  }

  String get oreFormattate {
    final h = ore.floor();
    final m = ((ore - h) * 60).round();
    return m > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${h}h';
  }
}

/// Tipi di attività disponibili (specchio dell'enum PHP TipoAttivita).
enum TipoAttivita {
  sviluppo('sviluppo', 'Sviluppo'),
  analisi('analisi', 'Analisi'),
  supporto('supporto', 'Supporto'),
  meeting('meeting', 'Meeting'),
  formazione('formazione', 'Formazione'),
  altro('altro', 'Altro');

  final String value;
  final String label;
  const TipoAttivita(this.value, this.label);
}
