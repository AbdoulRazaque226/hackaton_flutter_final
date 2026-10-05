import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/distance.dart';
import '../../data/models/professional_profile.dart';
import 'category_image.dart';

/// Single Reference ProfessionalCard Component (Mission 2A & 2B)
class ProfessionalCard extends StatelessWidget {
  final ProfessionalProfile profile;
  final double? distanceKm;
  final VoidCallback? onTap;

  const ProfessionalCard({
    super.key,
    required this.profile,
    this.distanceKm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.fromContext(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName
                              : loc.text(
                                  'Professionnel anonyme',
                                  'Anonymous professional',
                                ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceMutedDark
                                : AppColors.brandPrimaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CategoryImage(metier: profile.metier, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  loc.metierLabel(profile.metier),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.brandPrimaryLight
                                        : AppColors.brandPrimaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AvailabilityBadge(disponible: profile.disponible),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                    _professionalLocation(profile, loc),
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (distanceKm != null) ...[
                    const Icon(
                      Icons.near_me_outlined,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDistance(distanceKm),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.person_search_outlined, size: 16),
                  label: Text(
                    loc.text('Voir le profil', 'View profile'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.touchTarget),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _professionalLocation(
    ProfessionalProfile profile,
    AppLocalizations loc,
  ) {
    if (profile.zoneIntervention.trim().isNotEmpty) {
      return profile.zoneIntervention;
    }
    final place = [
      profile.neighborhood,
      profile.city,
      profile.country,
    ].where((part) => part.trim().isNotEmpty).join(', ');
    return place.isNotEmpty
        ? place
        : loc.text('Zone non disponible', 'Area unavailable');
  }
}

/// AvailabilityBadge Component
class AvailabilityBadge extends StatelessWidget {
  final bool disponible;

  const AvailabilityBadge({super.key, required this.disponible});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final bg = disponible
        ? AppColors.successContainer
        : AppColors.errorContainer;
    final fg = disponible ? AppColors.success : AppColors.error;
    final text = disponible
        ? loc.text('Disponible', 'Available')
        : loc.text('Indisponible', 'Unavailable');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            disponible ? Icons.check_circle : Icons.do_not_disturb_on,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
