import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'state/download_controller.dart';
import 'ui/home_page.dart';
import 'ui/theme/app_colors.dart';
import 'ui/theme/app_typography.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setAsFrameless();
    await windowManager.show();
  });
  runApp(
    ChangeNotifierProvider(
      create: (_) => DownloadController(),
      child: const DockerImageDownloaderApp(),
    ),
  );
}

class DockerImageDownloaderApp extends StatelessWidget {
  const DockerImageDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Docker Image Downloader',
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
