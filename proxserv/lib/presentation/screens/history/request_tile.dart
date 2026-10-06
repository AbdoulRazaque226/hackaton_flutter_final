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
  final Future<void> Function(int note, String? commentaire)? onRate;

  const RequestTile({
    super.key,
    required this.request,
    required this.role,
    this.proName,
    this.unread = false,
    this.onTap,
    this.onRate,
  });

  Future<void> _showRatingDialog(BuildContext context) async {
    final loc = AppLocalizations.fromContext(context);
    final result = await showDialog<_ReviewInput>(
      context: context,
      builder: (context) => _RequestRatingDialog(loc: loc),
    );
    if (result == null || onRate == null) return;

    try {
      await onRate!(result.note, result.commentaire);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.text('Merci pour votre avis.', 'Thank you for your review.')),
        ),
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RequestTile',
          context: ErrorDescription('while submitting a service review'),
        ),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.text(
              'Votre avis n’a pas pu être envoyé. Réessayez.',
              'Your review could not be sent. Please try again.',
            ),
          ),
        ),
      );
    }
  }

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
              if (isClient && request.status == RequestStatus.terminee) ...[
                const SizedBox(height: 8),
                if (request.note == null && onRate != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRatingDialog(context),
                      icon: const Icon(Icons.star_outline),
                      label: Text(loc.text('Donner mon avis', 'Leave a review')),
                    ),
                  )
                else if (request.note != null)
                  _RequestReviewSummary(
                    note: request.note!,
                    commentaire: request.commentaire,
                    loc: loc,
                  ),
              ],
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 380;
                  final date = Row(
                    mainAxisSize: MainAxisSize.min,
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
                    ],
                  );
                  final chatStatus = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        unread
                            ? loc.text('Non lu', 'Unread')
                            : loc.text('Ouvrir le chat', 'Open chat'),
                        style: (unread
                                ? theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  )
                                : theme.textTheme.bodySmall)
                            ?.copyWith(
                              color: unread
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                      ),
                    ],
                  );
                  return compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            date,
                            const SizedBox(height: 6),
                            chatStatus,
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [date, chatStatus],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewInput {
  final int note;
  final String? commentaire;

  const _ReviewInput(this.note, this.commentaire);
}

class _RequestRatingDialog extends StatefulWidget {
  final AppLocalizations loc;

  const _RequestRatingDialog({required this.loc});

  @override
  State<_RequestRatingDialog> createState() => _RequestRatingDialogState();
}

class _RequestRatingDialogState extends State<_RequestRatingDialog> {
  final _commentController = TextEditingController();
  int? _note;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return AlertDialog(
      scrollable: true,
      title: Text(loc.text('Évaluer l’intervention', 'Review the service')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.text('Votre note', 'Your rating')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                for (var value = 1; value <= 5; value++)
                  Semantics(
                    button: true,
                    selected: _note == value,
                    label: loc.text('$value sur 5 étoiles', '$value out of 5 stars'),
                    child: IconButton(
                      tooltip: loc.text(
                        '$value étoile${value > 1 ? 's' : ''}',
                        '$value star${value > 1 ? 's' : ''}',
                      ),
                      onPressed: () => setState(() => _note = value),
                      icon: Icon(
                        _note != null && value <= _note!
                            ? Icons.star
                            : Icons.star_outline,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: loc.text('Commentaire (facultatif)', 'Comment (optional)'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.text('Annuler', 'Cancel')),
        ),
        FilledButton(
          onPressed: _note == null
              ? null
              : () => Navigator.pop(
                    context,
                    _ReviewInput(
                      _note!,
                      _commentController.text.trim().isEmpty
                          ? null
                          : _commentController.text.trim(),
                    ),
                  ),
          child: Text(loc.text('Envoyer', 'Submit')),
        ),
      ],
    );
  }
}

class _RequestReviewSummary extends StatelessWidget {
  final int note;
  final String? commentaire;
  final AppLocalizations loc;

  const _RequestReviewSummary({
    required this.note,
    required this.commentaire,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var value = 1; value <= 5; value++)
                Icon(
                  value <= note ? Icons.star : Icons.star_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              const SizedBox(width: 8),
              Text(loc.text('Votre avis', 'Your review')),
            ],
          ),
          if (commentaire?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(commentaire!),
            ),
        ],
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
