import 'package:flutter/material.dart';
import 'package:macos_window_utils/widgets/transparent_macos_sidebar.dart';

// Wrapper che abilita l'effetto vetro smerigliato macOS.
// Usare dopo aver chiamato WindowManipulator.setMaterial(NSVisualEffectViewMaterial.sidebar).
class FrostedContainer extends StatelessWidget {
  final Widget child;
  const FrostedContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TransparentMacOSSidebar(child: child);
  }
}
