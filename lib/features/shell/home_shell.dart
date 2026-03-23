import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../features/info/info_provider.dart';
import '../../shared/widgets/frosted_container.dart';
import '../../shared/widgets/wtech_logo.dart';

class HomeShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;
  const HomeShell({super.key, required this.shell});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _tabs = [
    (label: 'Progetto', icon: Icons.folder_outlined),
    (label: 'Registra', icon: Icons.play_circle_outline),
    (label: 'Oggi', icon: Icons.today_outlined),
    (label: 'Settimana', icon: Icons.calendar_view_week_outlined),
  ];

  @override
  void initState() {
    super.initState();
    // Avvia il check aggiornamenti subito, così il badge appare senza aprire il tab Info
    Future.microtask(() => ref.read(infoProvider.notifier).init());
  }

  Future<void> _logout(BuildContext context) async {
    final storage = ref.read(tokenStorageProvider);
    await storage.cancella();
    ref.invalidate(authStateProvider);
    if (context.mounted) context.go('/setup');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shell = widget.shell;
    return FrostedContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _LogoHeader(cs: cs, onLogout: () => _logout(context)),
            Expanded(child: shell),
          ],
        ),
        bottomNavigationBar: Container(
          height: 52,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _TabItem(
                    label: _tabs[i].label,
                    icon: _tabs[i].icon,
                    selected: shell.currentIndex == i,
                    onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                  ),
                ),
              Expanded(
                child: _LogoTabItem(
                  label: 'Info',
                  selected: shell.currentIndex == 4,
                  onTap: () => shell.goBranch(4, initialLocation: 4 == shell.currentIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onLogout;
  const _LogoHeader({required this.cs, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    // 28px di clearance per i semafori macOS (TitleBarStyle.hidden)
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 4, top: 28, bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          const Expanded(child: WtechLogo(height: 22)),
          IconButton(
            onPressed: onLogout,
            icon: Icon(Icons.logout, size: 18, color: cs.onSurface.withValues(alpha: 0.45)),
            tooltip: 'Logout',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TabItem({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoTabItem extends ConsumerWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LogoTabItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5);
    final hasUpdate = ref.watch(infoProvider).updateStatus == UpdateStatus.updateAvailable;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                child: const WtechLogo(height: 22, brandmarkOnly: true),
              ),
              if (hasUpdate)
                Positioned(
                  top: -3,
                  right: -5,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
