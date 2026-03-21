import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/pending_timer_entry.dart';
import '../../core/providers/selected_project_provider.dart';
import '../timesheet/timesheet_provider.dart';
import '../week/week_provider.dart';
import 'timer_provider.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  bool _mostraFormManuale = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final selectedProject = ref.watch(selectedProjectProvider);
    final cs = Theme.of(context).colorScheme;

    // Conferma dopo stop timer
    if (state.pendingEntry != null) {
      return _ConfermaView(
        entry: state.pendingEntry!,
        loading: state.loading,
        errore: state.errore,
        notifier: notifier,
        cs: cs,
      );
    }

    // Registrazione manuale
    if (_mostraFormManuale) {
      return _RegistrazioneManuale(
        project: selectedProject,
        loading: state.loading,
        errore: state.errore,
        notifier: notifier,
        cs: cs,
        onSalvato: () => setState(() => _mostraFormManuale = false),
        onAnnulla: () => setState(() {
          _mostraFormManuale = false;
          // Pulisce l'eventuale errore rimasto
          if (state.errore != null) notifier.annullaSalvataggio();
        }),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: state.loading && !state.status.attivo
            ? const Center(child: CircularProgressIndicator())
            : state.status.attivo
                ? _TimerAttivoView(state: state, onStop: notifier.fermaTimer, cs: cs)
                : _TimerIdleView(
                    state: state,
                    progettoNome: selectedProject?.nome,
                    onAvvia: selectedProject != null
                        ? () => notifier.avviaTimer(selectedProject.id)
                        : null,
                    onRegistraManuale: () => setState(() => _mostraFormManuale = true),
                    cs: cs,
                  ),
      ),
    );
  }
}

// ─── Vista timer attivo ───────────────────────────────────────────────────────

class _TimerAttivoView extends StatelessWidget {
  final TimerState state;
  final Future<void> Function() onStop;
  final ColorScheme cs;
  const _TimerAttivoView({required this.state, required this.onStop, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 10, color: cs.error),
            const SizedBox(width: 8),
            Text(
              state.status.progettoNome ?? 'Timer attivo',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const Spacer(),
        Text(
          state.status.elapsedFormattato,
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w200, letterSpacing: 2, color: cs.onSurface),
        ),
        const Spacer(),
        if (state.errore != null) ...[
          Text(state.errore!, style: TextStyle(color: cs.error, fontSize: 12)),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: state.loading ? null : onStop,
            icon: const Icon(Icons.stop_rounded, size: 18),
            label: const Text('Ferma e salva'),
            style: OutlinedButton.styleFrom(foregroundColor: cs.error, side: BorderSide(color: cs.error)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Vista idle: due bottoni ──────────────────────────────────────────────────

class _TimerIdleView extends StatelessWidget {
  final TimerState state;
  final String? progettoNome;
  final VoidCallback? onAvvia;
  final VoidCallback onRegistraManuale;
  final ColorScheme cs;

  const _TimerIdleView({
    required this.state,
    required this.progettoNome,
    required this.onAvvia,
    required this.onRegistraManuale,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Progetto selezionato
        if (progettoNome != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(border: Border.all(color: cs.outline), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(progettoNome!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface), overflow: TextOverflow.ellipsis),
                ),
                TextButton(
                  onPressed: () => context.go('/home/projects'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Cambia', style: TextStyle(fontSize: 12, color: cs.primary)),
                ),
              ],
            ),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: () => context.go('/home/projects'),
            icon: const Icon(Icons.folder_outlined, size: 16),
            label: const Text('Seleziona un progetto'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
          ),
        ],
        const Spacer(),
        if (state.errore != null) ...[
          Text(state.errore!, style: TextStyle(color: cs.error, fontSize: 12)),
          const SizedBox(height: 8),
        ],
        // Due bottoni principali
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: onAvvia == null || state.loading ? null : onAvvia,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Avvia timer'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: progettoNome == null || state.loading ? null : onRegistraManuale,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Inserisci ore'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Form registrazione manuale ───────────────────────────────────────────────

class _RegistrazioneManuale extends ConsumerStatefulWidget {
  final dynamic project;
  final bool loading;
  final String? errore;
  final TimerNotifier notifier;
  final ColorScheme cs;
  final VoidCallback onSalvato;
  final VoidCallback onAnnulla;

  const _RegistrazioneManuale({
    required this.project,
    required this.loading,
    required this.errore,
    required this.notifier,
    required this.cs,
    required this.onSalvato,
    required this.onAnnulla,
  });

  @override
  ConsumerState<_RegistrazioneManuale> createState() => _RegistrazioneManualeState();
}

class _RegistrazioneManualeState extends ConsumerState<_RegistrazioneManuale> {
  double _ore = 1.0;
  TipoAttivita? _tipoAttivita;
  final _descrizioneCtrl = TextEditingController();
  bool _salvato = false;

  @override
  void dispose() {
    _descrizioneCtrl.dispose();
    super.dispose();
  }

  void _incrementa() => setState(() => _ore = ((_ore + 0.25) * 4).round() / 4);
  void _decrementa() => setState(() => _ore = ((_ore - 0.25).clamp(0.25, 24.0) * 4).round() / 4);

  String get _oreFormattate {
    final h = _ore.floor();
    final m = ((_ore - h) * 60).round();
    return m > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${h}h';
  }

  Future<void> _salva() async {
    await widget.notifier.registraOreManuale(
      projectId: widget.project.id,
      ore: _ore,
      tipoAttivita: _tipoAttivita!,
      descrizione: _descrizioneCtrl.text.trim().isEmpty ? null : _descrizioneCtrl.text.trim(),
    );
    // Controlla se ha avuto successo (nessun errore nel provider)
    if (!mounted) return;
    final state = ref.read(timerProvider);
    if (state.errore == null) {
      ref.invalidate(timesheetProvider);
      ref.invalidate(weekProvider);
      _salvato = true;
      widget.onSalvato();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_salvato) return const SizedBox.shrink();
    final cs = widget.cs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progetto + stepper ore
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.project?.nome ?? '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface)),
                        Text('Oggi', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  // Stepper ore
                  Row(
                    children: [
                      _StepBtn(icon: Icons.remove, onTap: _ore > 0.25 ? _decrementa : null, cs: cs),
                      SizedBox(
                        width: 56,
                        child: Text(_oreFormattate, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: cs.primary)),
                      ),
                      _StepBtn(icon: Icons.add, onTap: _ore < 24 ? _incrementa : null, cs: cs),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tipo attività
            Text('Tipo attività', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: TipoAttivita.values.map((t) {
                final sel = _tipoAttivita == t;
                return GestureDetector(
                  onTap: () => setState(() => _tipoAttivita = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t.label,
                        style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            color: sel ? cs.onPrimary : cs.onSurface)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Descrizione
            Text('Descrizione (opzionale)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 6),
            TextField(
              controller: _descrizioneCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Breve descrizione…',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            if (widget.errore != null) ...[
              const SizedBox(height: 10),
              Text(widget.errore!, style: TextStyle(color: cs.error, fontSize: 12)),
            ],

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: widget.loading ? null : widget.onAnnulla,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Icon(Icons.close_rounded, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: (_tipoAttivita == null || widget.loading) ? null : _salva,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: widget.loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 22),
                      label: const Text('Salva', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme cs;
  const _StepBtn({required this.icon, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: onTap != null ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? cs.primary : cs.onSurface.withValues(alpha: 0.3)),
      ),
    );
  }
}

// ─── Vista conferma dopo stop timer ──────────────────────────────────────────

class _ConfermaView extends ConsumerStatefulWidget {
  final PendingTimerEntry entry;
  final bool loading;
  final String? errore;
  final TimerNotifier notifier;
  final ColorScheme cs;

  const _ConfermaView({
    required this.entry,
    required this.loading,
    required this.errore,
    required this.notifier,
    required this.cs,
  });

  @override
  ConsumerState<_ConfermaView> createState() => _ConfermaViewState();
}

class _ConfermaViewState extends ConsumerState<_ConfermaView> {
  TipoAttivita? _tipoAttivita;
  final _descrizioneCtrl = TextEditingController();

  @override
  void dispose() {
    _descrizioneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TimerState>(timerProvider, (prev, next) {
      if (prev?.pendingEntry != null && next.pendingEntry == null && next.errore == null) {
        ref.invalidate(timesheetProvider);
        ref.invalidate(weekProvider);
      }
    });

    final cs = widget.cs;
    final entry = widget.entry;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.progettoNome ?? 'Progetto',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text(entry.oreFormattate,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w200, color: cs.primary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Tipo attività', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: TipoAttivita.values.map((t) {
                final sel = _tipoAttivita == t;
                return GestureDetector(
                  onTap: () => setState(() => _tipoAttivita = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t.label,
                        style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            color: sel ? cs.onPrimary : cs.onSurface)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text('Descrizione (opzionale)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 6),
            TextField(
              controller: _descrizioneCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Breve descrizione del lavoro svolto…',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (widget.errore != null) ...[
              const SizedBox(height: 10),
              Text(widget.errore!, style: TextStyle(color: cs.error, fontSize: 12)),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: widget.loading ? null : widget.notifier.annullaSalvataggio,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Icon(Icons.close_rounded, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: (_tipoAttivita == null || widget.loading)
                          ? null
                          : () => widget.notifier.confermaSalvataggio(
                                tipoAttivita: _tipoAttivita!,
                                descrizione: _descrizioneCtrl.text.trim().isEmpty
                                    ? null
                                    : _descrizioneCtrl.text.trim(),
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: widget.loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 22),
                      label: const Text('Salva', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
