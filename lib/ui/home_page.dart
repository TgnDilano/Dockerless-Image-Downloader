import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/download_progress.dart';
import '../state/download_controller.dart';
import 'widgets/image_input_card.dart';
import 'widgets/layer_progress_tile.dart';
import 'widgets/log_console.dart';
import 'widgets/result_banner.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _imageController = TextEditingController();
  final _scrollController = ScrollController();
  final _logScrollController = ScrollController();

  String? _selectedPath;
  String? _validationError;
  bool _isPackaging = false;
  int _fileCount = 0;
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _setDefaultPath();
    _imageController.addListener(() {
      _validateInput(_imageController.text);
    });
  }

  Future<void> _setDefaultPath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloads = Directory('${dir.path}${Platform.pathSeparator}..${Platform.pathSeparator}Downloads');
      if (await downloads.exists()) {
        _selectedPath = downloads.path;
      } else {
        _selectedPath = dir.path;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _validateInput(String value) {
    if (value.trim().isEmpty) {
      setState(() => _validationError = null);
      return;
    }
    final imageRefPattern = RegExp(
      r'^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)?'
      r'(:(?:[a-zA-Z0-9_][a-zA-Z0-9._-]*)?'
      r')?(?:@sha256:[a-f0-9]{64})?$',
    );
    if (!imageRefPattern.hasMatch(value.trim())) {
      setState(() {
        _validationError =
            'Invalid format. Use [namespace/]name[:tag][@sha256:digest]';
      });
    } else {
      setState(() => _validationError = null);
    }
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => _selectedPath = result);
    }
  }

  Future<void> _startDownload() async {
    final controller = context.read<DownloadController>();
    await controller.startDownload(
      _imageController.text.trim(),
      _selectedPath!,
    );
    if (controller.state.phase == DownloadPhase.done) {
      await _countFiles(controller.state.outputPath!);
    }
  }

  Future<void> _countFiles(String path) async {
    try {
      final dir = Directory(path);
      int count = 0;
      int size = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          count++;
          size += await entity.length();
        }
      }
      setState(() {
        _fileCount = count;
        _totalSize = size;
      });
    } catch (_) {}
  }

  Future<void> _packageAsTar() async {
    setState(() => _isPackaging = true);
    try {
      final controller = context.read<DownloadController>();
      await controller.packageAsTar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Packaged as .tar successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to package: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPackaging = false);
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    _scrollController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.download_outlined,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Docker Image Downloader'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Docker Image Downloader',
              applicationVersion: 'v0.1.0',
              applicationLegalese:
                  'Downloads Docker images without Docker.\n'
                  'Reference: github.com/moby/moby/blob/master/contrib/download-frozen-image-v2.sh',
              children: [
                const SizedBox(height: 16),
                Text(
                  'Built with Flutter for Windows desktop.\n'
                  'Docker Hub public images only  •  amd64 only',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<DownloadController>(
        builder: (context, controller, _) {
          final state = controller.state;
          final isDownloading = state.phase == DownloadPhase.authenticating ||
              state.phase == DownloadPhase.fetchingManifest ||
              state.phase == DownloadPhase.resolvingManifest ||
              state.phase == DownloadPhase.downloadingLayers ||
              state.phase == DownloadPhase.finalizing;
          final isDone = state.phase == DownloadPhase.done;
          final isError = state.phase == DownloadPhase.error;

          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Step indicator
                if (isDownloading || isDone || isError)
                  _buildStepIndicator(state.phase, colorScheme, theme),
                // Input card
                ImageInputCard(
                  controller: _imageController,
                  selectedPath: _selectedPath,
                  isLoading: isDownloading,
                  validationError: _validationError,
                  onBrowse: _pickFolder,
                  onDownload: _startDownload,
                  onReset: isDone || isError ? _resetAll : null,
                ),
                // Error banner
                if (isError && state.errorMessage != null)
                  _buildErrorBanner(state.errorMessage!, controller, colorScheme, theme),
                // Layer progress
                if (state.layers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Layers',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...List.generate(state.layers.length, (i) {
                    return LayerProgressTile(
                      progress: state.layers[i],
                      isLast: i == state.layers.length - 1,
                    );
                  }),
                ],
                // Log console
                if (state.logLines.isNotEmpty)
                  LogConsole(
                    lines: state.logLines,
                    scrollController: _logScrollController,
                  ),
                // Result banner
                if (isDone && state.outputPath != null)
                  ResultBanner(
                    outputPath: state.outputPath!,
                    fileCount: _fileCount,
                    totalSize: _totalSize,
                    onPackage: _packageAsTar,
                    onDownloadAnother: _resetAll,
                    isPackaging: _isPackaging,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(
    DownloadPhase phase,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final steps = [
      ('Auth', DownloadPhase.authenticating),
      ('Manifest', DownloadPhase.fetchingManifest),
      ('Layers', DownloadPhase.downloadingLayers),
      ('Finalize', DownloadPhase.finalizing),
    ];

    int activeIndex = -1;
    for (int i = 0; i < steps.length; i++) {
      if (phase.index >= steps[i].$2.index) {
        activeIndex = i;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < activeIndex
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isActive = stepIndex <= activeIndex;
          final isCurrent = phase == steps[stepIndex].$2;

          return Tooltip(
            message: steps[stepIndex].$1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCurrent
                        ? Icons.circle
                        : isActive
                            ? Icons.check
                            : Icons.circle_outlined,
                    size: 14,
                    color: isActive
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    steps[stepIndex].$1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorBanner(
    String message,
    DownloadController controller,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download failed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: controller.retry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetAll() {
    setState(() {
      _fileCount = 0;
      _totalSize = 0;
      _isPackaging = false;
    });
    _imageController.clear();
    context.read<DownloadController>().reset();
  }
}
