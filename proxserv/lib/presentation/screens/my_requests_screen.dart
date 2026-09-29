import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/models/service_request.dart';
import '../../data/services/firebase_service.dart';

/// Écran permettant au client de suivre ses demandes d'intervention.
class MyRequestsScreen extends StatelessWidget {
  final String? clientId;
  final FirebaseService firebaseService;

  MyRequestsScreen({
    super.key,
    this.clientId,
    FirebaseService? firebaseService,
  }) : firebaseService = firebaseService ?? FirebaseService();

  @override
  Widget build(BuildContext context) {
    final effectiveClientId =
        clientId ?? firebaseService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes d\'intervention'),
      ),
      body: effectiveClientId.isEmpty
          ? const Center(
              child: Text(
                'Aucun client connecté. Veuillez vous connecter pour voir vos demandes.',
                textAlign: TextAlign.center,
              ),
            )
          : StreamBuilder<List<ServiceRequest>>(
              stream: firebaseService.watchRequestsForClient(effectiveClientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Erreur lors du chargement des demandes : ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune demande d\'intervention pour le moment.',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _RequestItemCard(request: request);
                  },
                );
              },
            ),
    );
  }
}

class _RequestItemCard extends StatelessWidget {
  final ServiceRequest request;

  const _RequestItemCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.metier.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(context, request.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Description :',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.description.isNotEmpty
                  ? request.description
                  : 'Aucune description fournie.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Pro ID : ${request.professionalId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(request.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, RequestStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case RequestStatus.enAttente:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_empty;
        break;
      case RequestStatus.acceptee:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        icon = Icons.check_circle_outline;
        break;
      case RequestStatus.refusee:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        break;
      case RequestStatus.terminee:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.task_alt;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
