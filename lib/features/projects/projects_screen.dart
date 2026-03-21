import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/project.dart';
import '../../core/providers/selected_project_provider.dart';

final _projectsProvider = FutureProvider<List<Project>>((ref) async {
  final client = ref.watch(apiClientProvider).valueOrNull;
  if (client == null) return [];
  return client.getProjects();
});

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(_projectsProvider);
    final selected = ref.watch(selectedProjectProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progetto attivo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('Seleziona il progetto su cui stai lavorando.',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            Expanded(
              child: projectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: cs.error, size: 32),
                      const SizedBox(height: 8),
                      Text('Errore caricamento progetti',
                          style: TextStyle(color: cs.error, fontSize: 12)),
                      TextButton(
                        onPressed: () => ref.invalidate(_projectsProvider),
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
                data: (progetti) => ListView.separated(
                  itemCount: progetti.length,
                  separatorBuilder: (ctx, i) =>
                      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                  itemBuilder: (_, i) {
                    final p = progetti[i];
                    final isSelected = selected?.id == p.id;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 20,
                        color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
                      ),
                      title: Text(p.nome,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? cs.primary : cs.onSurface,
                          )),
                      onTap: () {
                        ref.read(selectedProjectProvider.notifier).state = p;
                        // Vai al tab Timer dopo la selezione
                        context.go('/home/timer');
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
