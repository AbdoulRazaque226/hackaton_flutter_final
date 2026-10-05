import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class BrandLogo extends StatelessWidget {
  final double height;

  const BrandLogo({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.jpg',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Semantics(
        label: 'ProxServ',
        child: Container(
          width: height * 1.25,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Icon(
            Icons.home_repair_service_outlined,
            size: height * 0.68,
            color: AppColors.brandPrimary,
          ),
        ),
      ),
    );
  }
}
