import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/selected_project_provider.dart';
import 'timer_provider.dart';

/// Schermata principale del timer — mostra idle o timer attivo.
class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final selectedProject = ref.watch(selectedProjectProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: state.loading && !state.status.attivo
            ? const Center(child: CircularProgressIndicator())
            : state.status.attivo
                ? _TimerAttivoView(
                    state: state,
                    onStop: notifier.fermaTimer,
                    cs: cs,
                  )
                : _TimerIdleView(
                    state: state,
                    progettoNome: selectedProject?.nome,
                    progettoId: selectedProject?.id,
                    onAvvia: selectedProject != null
                        ? () => notifier.avviaTimer(selectedProject.id)
                        : null,
                    cs: cs,
                  ),
      ),
    );
  }
}

/// Vista quando il timer è in corso: mostra progetto, contatore e bottone stop.
class _TimerAttivoView extends StatelessWidget {
  final TimerState state;
  final Future<void> Function() onStop;
  final ColorScheme cs;

  const _TimerAttivoView({
    required this.state,
    required this.onStop,
    required this.cs,
  });

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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          state.status.elapsedFormattato,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            letterSpacing: 2,
            color: cs.onSurface,
          ),
        ),
        const Spacer(),
        if (state.errore != null) ...[
          Text(
            state.errore!,
            style: TextStyle(color: cs.error, fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: state.loading ? null : onStop,
            icon: const Icon(Icons.stop_rounded, size: 18),
            label: const Text('Ferma e salva'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Vista idle: mostra progetto selezionato e bottone avvia.
class _TimerIdleView extends StatelessWidget {
  final TimerState state;
  final String? progettoNome;
  final int? progettoId;
  final VoidCallback? onAvvia;
  final ColorScheme cs;

  const _TimerIdleView({
    required this.state,
    required this.progettoNome,
    required this.progettoId,
    required this.onAvvia,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Avvia timer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        if (progettoNome != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progettoNome!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/home/projects'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
        const Spacer(),
        if (state.errore != null) ...[
          Text(
            state.errore!,
            style: TextStyle(color: cs.error, fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAvvia == null || state.loading ? null : onAvvia,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Avvia'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
