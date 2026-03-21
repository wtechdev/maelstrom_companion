import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/entry_tile.dart';
import 'timesheet_provider.dart';

class TimesheetScreen extends ConsumerWidget {
  const TimesheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timesheetProvider);
    final notifier = ref.read(timesheetProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final oggi = DateFormat('EEEE d MMMM', 'it').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: notifier.carica,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Oggi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
                          Text(oggi, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    if (state.voci.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(state.totaleFormattato,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
                      ),
                  ],
                ),
              ),
            ),
            if (state.loading && state.voci.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (state.errore != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: cs.error, size: 32),
                      const SizedBox(height: 8),
                      Text(state.errore!, style: TextStyle(color: cs.error, fontSize: 12)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: notifier.carica, child: const Text('Riprova')),
                    ],
                  ),
                ),
              )
            else if (state.voci.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty, size: 36, color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text('Nessuna registrazione oggi', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList.separated(
                  itemCount: state.voci.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                  itemBuilder: (_, i) => EntryTile(entry: state.voci[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
