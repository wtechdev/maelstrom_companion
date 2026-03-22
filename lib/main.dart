import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:macos_window_utils/macos/ns_visual_effect_view_material.dart';
import 'package:macos_window_utils/window_manipulator.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'shared/theme/app_theme.dart';
import 'shared/tray/tray_manager_service.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it');
  await WindowManager.instance.ensureInitialized();
  await WindowManipulator.initialize(enableWindowDelegate: false);

  final windowOptions = WindowOptions(
    size: const Size(AppTheme.windowWidth, AppTheme.windowHeight),
    minimumSize: const Size(AppTheme.windowWidth, AppTheme.windowHeight),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Maelstrom',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setResizable(true);
    await windowManager.hide();
  });

  await WindowManipulator.setMaterial(NSVisualEffectViewMaterial.sidebar);
  await TrayManagerService.init();

  runApp(const ProviderScope(child: MaelstromApp()));
}

class MaelstromApp extends ConsumerStatefulWidget {
  const MaelstromApp({super.key});
  @override
  ConsumerState<MaelstromApp> createState() => _MaelstromAppState();
}

class _MaelstromAppState extends ConsumerState<MaelstromApp>
    with TrayListener, WindowListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() => TrayManagerService.gestisciClick();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key != null) TrayManagerService.gestisciMenuClick(menuItem.key!);
  }

  @override
  void onWindowBlur() => windowManager.hide();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter(ref),
    );
  }
}
