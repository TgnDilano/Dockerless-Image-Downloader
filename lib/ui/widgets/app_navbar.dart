import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppNavbar extends StatelessWidget {
  const AppNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.hold,
        border: Border(
          bottom: BorderSide(color: Color(0xFF202020)),
        ),
      ),
      child: Row(
        children: [
          // Left: brand
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.stencilOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dockless',
                style: AppTypography.display(
                  size: 17,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16344A),
                  border: Border.all(color: const Color(0xFF2F5F80)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v1.2.0',
                  style: AppTypography.mono(
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF6CC3F5),
                  ),
                ),
              ),
            ],
          ),
          // Center: search bar
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2028),
                  border: Border.all(color: const Color(0xFF2C313B)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search, size: 17, color: Color(0xFF6B7280)),
                    const SizedBox(width: 10),
                    Text(
                      'iwomi/agencybanking-frontoffice:advans-v1.1.17',
                      style: AppTypography.mono(
                        size: 13,
                        color: const Color(0xFFD7DBE0),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Right: status + gear
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF123321),
                  border: Border.all(color: const Color(0xFF1F5C34)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF34C759),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF34C759).withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Registry Connected',
                      style: AppTypography.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: const Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF8A92A0)),
            ],
          ),
        ],
      ),
    );
  }
}
