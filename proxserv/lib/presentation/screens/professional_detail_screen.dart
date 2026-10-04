import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
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
    final isDark = theme.brightness == Brightness.dark;

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
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec avatar, nom, métier et statut
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : 'P',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.displayName.isNotEmpty
                            ? profile.displayName
                            : loc.text(
                                'Professionnel anonyme',
                                'Anonymous professional',
                              ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(
                          loc.metierLabel(profile.metier),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                      ),
                      const SizedBox(height: 12),
                      AvailabilityBadge(disponible: profile.disponible),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Divider(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                const SizedBox(height: 16),

                Text(
                  loc.text(
                    'Informations du professionnel',
                    'Professional information',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        _buildInfoRow(
                          context: context,
                          icon: Icons.location_on_outlined,
                          title: loc.text(
                            'Zone d\'intervention',
                            'Service area',
                          ),
                          value: profile.zoneIntervention.isNotEmpty
                              ? profile.zoneIntervention
                              : loc.text('Non renseignée', 'Not provided'),
                        ),
                        Divider(
                          height: 24,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
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

                const SizedBox(height: 32),

                // Action Principale (CTA) : Demander une intervention
                SizedBox(
                  width: double.infinity,
                  height: 52,
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

                const SizedBox(height: 12),

                // Action Secondaire : Appeler le professionnel
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: profile.disponible
                        ? () => _makePhoneCall(context)
                        : null,
                    icon: const Icon(Icons.phone),
                    label: Text(
                      profile.disponible
                          ? loc.callPro
                          : loc.text(
                              'Téléphone indisponible',
                              'Phone unavailable',
                            ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: profile.disponible
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
}
