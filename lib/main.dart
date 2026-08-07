import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'state/download_controller.dart';
import 'ui/home_page.dart';
import 'ui/theme/app_colors.dart';
import 'ui/theme/app_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await _initWindow();
  runApp(
    ChangeNotifierProvider(
      create: (_) => DownloadController(),
      child: const DockerImageDownloaderApp(),
    ),
  );
}

/// Frameless, fixed-size window on Windows, driven by window_manager.
Future<void> _initWindow() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }

  await windowManager.ensureInitialized();

  const size = Size(1024, 640);
  final options = const WindowOptions(
    size: size,
    minimumSize: Size(800, 500),
    // no maximumSize -> allows growing
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setResizable(true); // <-- this was your bug
    await windowManager.setMaximizable(true);
    await windowManager.setMinimizable(true);

    if (defaultTargetPlatform == TargetPlatform.windows) {
      await windowManager.setAsFrameless();
    }

    await windowManager.show();
    await windowManager.focus();
  });
}

class DockerImageDownloaderApp extends StatelessWidget {
  const DockerImageDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DockerXLess',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomePage(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ink,
      colorScheme: ColorScheme.dark(
        primary: AppColors.stencilOrange,
        secondary: AppColors.sealTeal,
        surface: AppColors.hold,
        error: AppColors.stencilOrange,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display(size: 26),
        displayMedium: AppTypography.display(size: 20),
        displaySmall: AppTypography.display(size: 15),
        bodyLarge: AppTypography.body(),
        bodyMedium: AppTypography.body(size: 13),
        bodySmall: AppTypography.body(size: 12),
        labelLarge: AppTypography.mono(size: 14),
        labelMedium: AppTypography.mono(size: 12),
        labelSmall: AppTypography.mono(size: 11),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.offWhite,
        elevation: 0,
      ),
    );
  }
}
