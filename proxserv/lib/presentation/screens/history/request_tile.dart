import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/service_request.dart';
import '../register_screen.dart' show metierIcon;
import '../../widgets/request_status_style.dart';

/// Carte d'une demande dans l'onglet Historique.
///
/// Le contenu s'adapte au rôle :
/// - côté **client** : titre = métier, puis le nom du professionnel ;
/// - côté **professionnel** : titre = métier, puis le nom du client.
///
/// Dans les deux cas la description de la demande sert de résumé court.
class RequestTile extends StatelessWidget {
  final ServiceRequest request;
  final UserRole role;

  /// Nom du professionnel résolu via `proDirectoryProvider` — inutile côté
  /// professionnel, qui affiche le client.
  final String? proName;

  /// Vrai si des messages non lus attendent cet utilisateur dans le fil.
  final bool unread;

  final VoidCallback? onTap;

  const RequestTile({
    super.key,
    required this.request,
    required this.role,
    this.proName,
    this.unread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.fromContext(context);
    final isClient = role == UserRole.client;

    final counterpart = isClient
        ? (proName?.isNotEmpty == true
              ? proName!
              : loc.text('Professionnel', 'Professional'))
        : (request.clientName.isNotEmpty
              ? request.clientName
              : loc.text('Client', 'Client'));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      metierIcon(request.metier),
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre : le métier demandé.
                        Text(
                          loc.metierLabel(request.metier),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Interlocuteur, du point de vue de l'utilisateur.
                        Text(
                          counterpart,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  RequestStatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: 12),
              // Résumé de la tâche.
              Text(
                request.description.isNotEmpty
                    ? request.description
                    : loc.text(
                        'Aucune description fournie.',
                        'No description provided.',
                      ),
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(request.createdAt, loc),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (unread)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc.text('Non lu', 'Unread'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          loc.text('Ouvrir le chat', 'Open chat'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille de statut — couleurs et libellés selon la Mission 2A.
class RequestStatusChip extends StatelessWidget {
  final RequestStatus status;

  const RequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final foreground = RequestStatusStyle.foreground(status);
    final background = RequestStatusStyle.background(
      status,
      Theme.of(context).brightness,
    );
    final icon = RequestStatusStyle.icon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            loc.statusLabel(status.name),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt, AppLocalizations loc) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return loc.isFr
      ? '$d/$m/${dt.year} à $h:$min'
      : '$m/$d/${dt.year} at $h:$min';
}
