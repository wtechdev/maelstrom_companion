import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_profile.dart';
import '../../shared/widgets/wtech_logo.dart';
import 'info_provider.dart';
import 'update_service.dart';

/// Tab "Info": mostra versione app, stato aggiornamenti, profilo utente e server.
class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(infoProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(infoProvider);
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('App', cs),
          const SizedBox(height: 6),
          _AppSection(state: state, cs: cs),
          const SizedBox(height: 16),
          _SectionLabel('Account', cs),
          const SizedBox(height: 6),
          _AccountSection(profilo: state.profilo, cs: cs),
          const SizedBox(height: 16),
          _SectionLabel('Server', cs),
          const SizedBox(height: 6),
          _ServerSection(serverUrl: state.serverUrl, cs: cs),
        ],
      ),
    );
  }
}

// ─── Sezione App ───────────────────────────────────────────────────────────────

class _AppSection extends ConsumerWidget {
  final InfoState state;
  final ColorScheme cs;

  const _AppSection({required this.state, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const WtechLogo(height: 28, brandmarkOnly: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maelstrom Companion',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (state.versione != null)
                      Text(
                        'Versione ${state.versione}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                  ],
                ),
              ),
              _UpdateBadge(state: state, cs: cs),
            ],
          ),
          if (state.updateStatus == UpdateStatus.downloading)
            _DownloadProgress(state: state, cs: cs),
          if (state.updateStatus == UpdateStatus.updateAvailable)
            _UpdateAvailableRow(state: state, cs: cs),
          const Divider(height: 16, thickness: 0.5),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => ref.read(infoProvider.notifier).checkUpdate(),
              child: Text(
                'Controlla aggiornamenti',
                style: TextStyle(color: cs.primary, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateBadge extends StatelessWidget {
  final InfoState state;
  final ColorScheme cs;

  const _UpdateBadge({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    switch (state.updateStatus) {
      case UpdateStatus.checking:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        );
      case UpdateStatus.upToDate:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '✓ Aggiornato',
            style: TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case UpdateStatus.error:
        return _ErrorRow(errore: state.errore, cs: cs);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ErrorRow extends StatelessWidget {
  final String? errore;
  final ColorScheme cs;

  const _ErrorRow({required this.errore, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                errore ?? 'Impossibile controllare aggiornamenti',
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ref.read(infoProvider.notifier).checkUpdate(),
              child: Text(
                'Riprova',
                style: TextStyle(color: cs.primary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateAvailableRow extends ConsumerWidget {
  final InfoState state;
  final ColorScheme cs;

  const _UpdateAvailableRow({required this.state, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'v${state.nuovaVersione} disponibile',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Attuale: v${state.versione}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _avviaAggiornamento(context, ref, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Aggiorna'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _avviaAggiornamento(
    BuildContext context,
    WidgetRef ref,
    InfoState state,
  ) async {
    if (state.dmgUrl == null) return;
    final notifier = ref.read(infoProvider.notifier);
    final service = UpdateService();
    final dmgPath = UpdateService.dmgPath(state.nuovaVersione ?? 'latest');
    final appPath = UpdateService.appInstallPath;

    try {
      await service.scaricaDmg(
        url: state.dmgUrl!,
        destinazione: dmgPath,
        onProgress: notifier.aggiornaProgress,
      );
      await service.avviaAggiornamento(dmgPath: dmgPath, appPath: appPath);
      exit(0);
    } catch (e) {
      notifier.impostaErrore('Aggiornamento fallito: $e');
    }
  }
}

class _DownloadProgress extends StatelessWidget {
  final InfoState state;
  final ColorScheme cs;

  const _DownloadProgress({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: state.downloadProgress,
            backgroundColor: cs.onSurface.withValues(alpha: 0.1),
            color: cs.primary,
            minHeight: 4,
          ),
          const SizedBox(height: 6),
          Text(
            state.downloadProgress != null
                ? 'Download ${(state.downloadProgress! * 100).toStringAsFixed(0)}%'
                : 'Download in corso...',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "L'app si riavvierà automaticamente",
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sezione Account ───────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  final UserProfile? profilo;
  final ColorScheme cs;

  const _AccountSection({required this.profilo, required this.cs});

  @override
  Widget build(BuildContext context) {
    if (profilo == null) {
      return _SectionBox(
        cs: cs,
        child: Text(
          'Non disponibile',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.45),
            fontSize: 12,
          ),
        ),
      );
    }
    return _SectionBox(
      cs: cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profilo!.nomeCompleto,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            profilo!.email,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
          ),
          if (profilo!.ruolo != null) ...[
            const SizedBox(height: 2),
            Text(
              'Ruolo: ${profilo!.ruolo}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          ],
          if (profilo!.struttura != null) ...[
            const SizedBox(height: 2),
            Text(
              'Struttura: ${profilo!.struttura}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sezione Server ────────────────────────────────────────────────────────────

class _ServerSection extends StatelessWidget {
  final String? serverUrl;
  final ColorScheme cs;

  const _ServerSection({required this.serverUrl, required this.cs});

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      cs: cs,
      child: Text(
        serverUrl ?? '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}

// ─── Widget comuni ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _SectionLabel(this.label, this.cs);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 0.5,
          color: cs.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  final Widget child;
  final ColorScheme cs;

  const _SectionBox({required this.child, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}
