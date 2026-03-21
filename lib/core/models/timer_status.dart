class TimerStatus {
  final bool attivo;
  final int? progettoId;
  final String? progettoNome;
  final DateTime? iniziato;
  const TimerStatus({
    required this.attivo,
    this.progettoId,
    this.progettoNome,
    this.iniziato,
  });
  factory TimerStatus.inattivo() => const TimerStatus(attivo: false);
  factory TimerStatus.fromJson(Map<String, dynamic> json) {
    final running = (json['active'] ?? json['running']) as bool? ?? false;
    return TimerStatus(
      attivo: running,
      progettoId: json['project_id'] as int?,
      progettoNome: json['project_name'] as String?,
      iniziato: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
    );
  }
  Duration get elapsed =>
      iniziato != null ? DateTime.now().difference(iniziato!) : Duration.zero;
  String get elapsedFormattato {
    final d = elapsed;
    final ore = d.inHours.toString().padLeft(2, '0');
    final min = (d.inMinutes % 60).toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$ore:$min:$sec';
  }
}
