import 'package:flutter/material.dart';

class ImageInputCard extends StatelessWidget {
  final TextEditingController controller;
  final String? selectedPath;
  final bool isLoading;
  final String? validationError;
  final VoidCallback onBrowse;
  final VoidCallback onDownload;
  final VoidCallback? onReset;

  const ImageInputCard({
    super.key,
    required this.controller,
    this.selectedPath,
    this.isLoading = false,
    this.validationError,
    required this.onBrowse,
    required this.onDownload,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Download a Docker image',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Image reference',
                hintText: 'e.g. alpine:latest',
                helperText: 'Format: [namespace/]name[:tag][@digest]',
                errorText: validationError,
                prefixIcon: const Icon(Icons.image_outlined),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onBrowse,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Output folder',
                        prefixIcon: Icon(Icons.folder_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedPath ?? 'Click Browse to select...',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selectedPath != null ? null : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Browse'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (selectedPath != null &&
                            controller.text.trim().isNotEmpty &&
                            validationError == null &&
                            !isLoading)
                        ? onDownload
                        : null,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(isLoading ? 'Downloading...' : 'Download'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                if (onReset != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
