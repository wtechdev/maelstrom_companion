import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/frosted_container.dart';
import '../../shared/widgets/wtech_logo.dart';

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const HomeShell({super.key, required this.shell});

  static const _tabs = [
    (label: 'Progetto', icon: Icons.folder_outlined),
    (label: 'Registra', icon: Icons.play_circle_outline),
    (label: 'Oggi', icon: Icons.today_outlined),
    (label: 'Settimana', icon: Icons.calendar_view_week_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FrostedContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _LogoHeader(cs: cs),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  final ColorScheme cs;
  const _LogoHeader({required this.cs});

  @override
  Widget build(BuildContext context) {
    // 28px di clearance per i semafori macOS (TitleBarStyle.hidden)
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: const WtechLogo(height: 22),
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
