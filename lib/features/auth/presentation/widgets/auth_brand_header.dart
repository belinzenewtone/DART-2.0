import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF0E1932), Color(0xFF050D1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.hub_outlined,
            size: 38,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'BELTECH',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Innovate and Create',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
