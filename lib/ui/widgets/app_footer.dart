import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.hold,
        border: Border(
          top: BorderSide(color: Color(0xFF202020)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sealTeal,
              boxShadow: [
                BoxShadow(
                  color: Color(0x262F6F62),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Pulled directly from the registry \u2014 no local Docker daemon needed.',
            style: AppTypography.mono(
              size: 11,
              color: AppColors.steelTextDim,
            ),
          ),
          const Spacer(),
          Text(
            'dockerless-image-downloader  v0.1.0',
            style: AppTypography.mono(size: 10, color: AppColors.steelTextDim),
          ),
        ],
      ),
    );
  }
}
