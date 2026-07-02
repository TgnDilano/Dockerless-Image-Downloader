import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FFFFFF),
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 60,
            offset: Offset(0, 30),
          ),
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            child: SizedBox(
              height: 18,
              child: CustomPaint(
                size: const Size(double.infinity, 18),
                painter: _PerforatedEdgePainter(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 22, 44, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARGO MANIFEST',
                            style: AppTypography.display(
                              size: 19,
                              color: AppColors.graphiteSoft,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter the image to fetch and where it should land.',
                            style: AppTypography.body(
                              size: 12.5,
                              color: AppColors.graphiteSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'FORM  [namespace/]name[:tag][@digest]',
                          style: AppTypography.mono(
                            size: 11,
                            color: AppColors.graphiteSoft,
                          ),
                        ),
                        Text(
                          'REV  2026.07.02',
                          style: AppTypography.mono(
                            size: 11,
                            color: AppColors.graphiteSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.paperLine),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildField(
                  label: 'IMAGE REFERENCE',
                  hint: 'required',
                  child: _FieldBox(
                    icon: Icons.image_outlined,
                    child: TextField(
                      controller: controller,
                      style: AppTypography.mono(
                        size: 14.5,
                        color: AppColors.graphite,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'e.g. alpine:latest',
                        hintStyle: AppTypography.mono(
                          size: 14.5,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _buildField(
                  label: 'OUTPUT FOLDER',
                  hint: 'defaults to Downloads',
                  child: Row(
                    children: [
                      Expanded(
                        child: _FieldBox(
                          icon: Icons.folder_outlined,
                          child: Text(
                            selectedPath ?? 'Click Browse to select...',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.mono(
                              size: 14.5,
                              color: AppColors.graphite,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _BrowseButton(onPressed: onBrowse),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _DownloadButton(
                        isLoading: isLoading,
                        onPressed:
                            (selectedPath != null &&
                                controller.text.trim().isNotEmpty &&
                                validationError == null &&
                                !isLoading)
                            ? onDownload
                            : null,
                      ),
                    ),
                    if (onReset != null) ...[
                      const SizedBox(width: 12),
                      _ResetButton(onPressed: onReset!),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: AppTypography.mono(
                  size: 11,
                  color: AppColors.graphiteSoft,
                  letterSpacing: 0.09,
                ),
              ),
              const Spacer(),
              Text(
                hint,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  color: const Color(0xFF9A927A),
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _FieldBox extends StatelessWidget {
  final IconData icon;
  final Widget child;
  const _FieldBox({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        border: Border.all(color: AppColors.paperLine),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.graphiteSoft),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BrowseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BrowseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.folder_open, size: 13),
        label: const Text('Browse'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.graphite,
          backgroundColor: AppColors.browseFill,
          side: const BorderSide(color: AppColors.paperLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          textStyle: AppTypography.body(size: 12.5, weight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _DownloadButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF3A4148),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sealTeal,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'DOWNLOADING\u2026',
              style: AppTypography.display(
                size: 15,
                color: const Color(0xFF9AA4AB),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.stencilOrange,
          disabledBackgroundColor: const Color(0xFF3A4148),
          disabledForegroundColor: const Color(0xFF9AA4AB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download,
              size: 17,
              color: onPressed != null
                  ? const Color(0xFFFFF6EE)
                  : const Color(0xFF9AA4AB),
            ),
            const SizedBox(width: 10),
            Text(
              'DOWNLOAD',
              style: AppTypography.display(
                size: 15,
                color: onPressed != null
                    ? const Color(0xFFFFF6EE)
                    : const Color(0xFF9AA4AB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ResetButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.refresh, size: 14),
        label: const Text('Reset'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.graphiteSoft,
          side: const BorderSide(
            color: AppColors.resetBorder,
            style: BorderStyle.solid,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          textStyle: AppTypography.body(size: 13, weight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}

class _PerforatedEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink.withValues(alpha: 0.9);
    const dotRadius = 4.0;
    const spacing = 22.0;
    double x = 11;
    while (x < size.width) {
      final centerY = size.height / 2;
      canvas.drawCircle(Offset(x, centerY), dotRadius, paint);
      x += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
