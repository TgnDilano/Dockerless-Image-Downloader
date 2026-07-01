import 'package:flutter/material.dart';

class AppAboutDialog extends StatelessWidget {
  const AppAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AboutDialog(
      applicationName: 'Docker Image Downloader',
      applicationVersion: 'v0.1.0',
      applicationLegalese: 'Downloads Docker images without Docker.\n'
          'Mirrors the functionality of Moby\'s download-frozen-image-v2.sh.',
      children: [
        const SizedBox(height: 16),
        Text(
          'Built with Flutter for Windows desktop.\n'
          'Supports: Docker Hub public images, amd64 architecture.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Reference: https://github.com/moby/moby/blob/master/contrib/download-frozen-image-v2.sh',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
