import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/professional_profile.dart';

/// Écran de fiche détaillée d'un professionnel.
class ProfessionalDetailScreen extends StatelessWidget {
  final ProfessionalProfile profile;
  final VoidCallback? onRequestIntervention;

  const ProfessionalDetailScreen({
    super.key,
    required this.profile,
    this.onRequestIntervention,
  });

  Future<void> _makePhoneCall(BuildContext context) async {
    if (profile.phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non renseigné.')),
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
              'Impossible de passer l\'appel vers ${profile.phone}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'appel : $e')));
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

    final ratingText = profile.noteMoyenne != null
        ? profile.noteMoyenne!.toStringAsFixed(1)
        : 'Non noté';

    final evalText = profile.nombreEvaluations > 0
        ? '${profile.nombreEvaluations} évaluation(s)'
        : 'Aucune évaluation';

    return Scaffold(
      appBar: AppBar(title: const Text('Fiche Professionnel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec avatar, nom, métier et statut
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName
                        : 'Professionnel anonyme',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(
                      profile.metier.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                  const SizedBox(height: 12),
                  _buildAvailabilityBadge(profile.disponible),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            Text(
              'Informations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context: context,
                      icon: Icons.phone,
                      title: 'Téléphone',
                      value: profile.phone.isNotEmpty
                          ? profile.phone
                          : 'Non renseigné',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.location_on,
                      title: 'Zone d\'intervention',
                      value: profile.zoneIntervention.isNotEmpty
                          ? profile.zoneIntervention
                          : 'Non renseignée',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.star,
                      iconColor: Colors.amber,
                      title: 'Note moyenne',
                      value: '$ratingText / 5  ($evalText)',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Boutons d'action
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _makePhoneCall(context),
                icon: const Icon(Icons.phone),
                label: const Text(
                  'Appeler le professionnel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _handleRequestIntervention(context),
                icon: const Icon(Icons.send),
                label: const Text(
                  'Demander une intervention',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityBadge(bool disponible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: disponible ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: disponible ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: disponible ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            disponible
                ? 'Disponible pour intervention'
                : 'Actuellement indisponible',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: disponible ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
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
