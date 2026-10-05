import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/professional_profile.dart';
import '../widgets/professional_card.dart';

/// Écran de fiche détaillée d'un professionnel (Mission 2A & 2B).
class ProfessionalDetailScreen extends StatelessWidget {
  final ProfessionalProfile profile;
  final VoidCallback? onRequestIntervention;

  const ProfessionalDetailScreen({
    super.key,
    required this.profile,
    this.onRequestIntervention,
  });

  Future<void> _makePhoneCall(BuildContext context) async {
    final loc = AppLocalizations.fromContext(context);
    if (profile.phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.text(
              'Numéro de téléphone non renseigné.',
              'Phone number not provided.',
            ),
          ),
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: profile.phone.trim());
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.text(
                'Impossible de passer l\'appel vers ${profile.phone}',
                'Unable to call ${profile.phone}',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.text('Erreur lors de l\'appel : $e', 'Call failed: $e'),
          ),
        ),
      );
    }
  }

  void _handleRequestIntervention(BuildContext context) {
    if (onRequestIntervention != null) {
      onRequestIntervention!();
    } else {
      context.push('/client/request-form', extra: profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.fromContext(context);
    final hasRealRating =
        profile.noteMoyenne != null && profile.nombreEvaluations > 0;

    final ratingText = hasRealRating
        ? profile.noteMoyenne!.toStringAsFixed(1)
        : 'Nouveau';

    final evalText = hasRealRating
        ? loc.text(
            '${profile.nombreEvaluations} évaluation(s)',
            '${profile.nombreEvaluations} review(s)',
          )
        : loc.text('Aucune évaluation', 'No reviews');

    return Scaffold(
      appBar: AppBar(title: Text(loc.proProfileTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 480;
                    final avatar = CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.surface,
                      child: Text(
                        profile.displayName.isNotEmpty
                            ? profile.displayName[0].toUpperCase()
                            : 'P',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                    final identity = Column(
                      crossAxisAlignment: compact
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName
                              : loc.text(
                                  'Professionnel anonyme',
                                  'Anonymous professional',
                                ),
                          style: theme.textTheme.headlineMedium,
                          textAlign: compact
                              ? TextAlign.center
                              : TextAlign.start,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          loc.metierLabel(profile.metier),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AvailabilityBadge(disponible: profile.disponible),
                      ],
                    );

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: AppSpacing.borderRadiusLg,
                      ),
                      child: compact
                          ? Column(
                              children: [
                                avatar,
                                const SizedBox(height: AppSpacing.md),
                                identity,
                              ],
                            )
                          : Row(
                              children: [
                                avatar,
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(child: identity),
                              ],
                            ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                Text(
                  loc.text(
                    'Informations du professionnel',
                    'Professional information',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context: context,
                          icon: Icons.phone_outlined,
                          title: loc.phoneLabel,
                          value: profile.phone.isNotEmpty
                              ? profile.phone
                              : loc.text('Non renseigné', 'Not provided'),
                        ),
                        Divider(
                          height: 24,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        _buildInfoRow(
                          context: context,
                          icon: Icons.location_on_outlined,
                          title: loc.text(
                            'Zone d\'intervention',
                            'Service area',
                          ),
                          value: _locationLabel(profile, loc),
                        ),
                        Divider(
                          height: 24,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        _buildInfoRow(
                          context: context,
                          icon: Icons.star_outline,
                          iconColor: AppColors.brandAccent,
                          title: loc.text('Note moyenne', 'Average rating'),
                          value: hasRealRating
                              ? '$ratingText / 5  ($evalText)'
                              : loc.noReviewsYet,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Action Principale (CTA) : Demander une intervention
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.touchTarget,
                  child: FilledButton.icon(
                    onPressed: () => _handleRequestIntervention(context),
                    icon: const Icon(Icons.send),
                    label: Text(
                      loc.requestIntervention,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Calling remains available when a real phone number is listed;
                // availability describes service status, not phone validity.
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.touchTarget,
                  child: OutlinedButton.icon(
                    key: const ValueKey('professional-call-button'),
                    onPressed: profile.phone.trim().isNotEmpty
                        ? () => _makePhoneCall(context)
                        : null,
                    icon: const Icon(Icons.phone),
                    label: Text(
                      profile.phone.trim().isNotEmpty
                          ? loc.callPro
                          : loc.text(
                              'Téléphone non renseigné',
                              'Phone number not provided',
                            ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: profile.phone.trim().isNotEmpty
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  loc.text(
                    'Après l’envoi d’une demande, vous pourrez lui écrire directement.',
                    'After sending a service request, you can message this professional.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _locationLabel(
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
