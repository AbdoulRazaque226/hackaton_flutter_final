import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/app_providers.dart';
import '../../data/models/service_request.dart';
import '../../data/models/enums.dart';

class ProfessionalDashboardScreen extends ConsumerWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Écoute du profil de l'artisan (pour le statut disponible)
    final profileAsync = ref.watch(professionalProfileProvider);
    //Écoute de la liste des demandes d'intervention en temps réel
    final requestsAsync = ref.watch(professionalRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tableau de Bord Artisan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F5234), // Vert ProxServ
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(firebaseAuthProvider).signOut(),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Erreur réseau. Vérifiez votre connexion. ($err)'),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Aucun profil professionnel trouvé.'),
            );
          }

          return Column(
            children: [
              // --- SECTION 1 : BANDEAU DE DISPONIBILITÉ (UI RÉACTIVE) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                color: profile.disponible
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          profile.disponible
                              ? Icons.check_circle
                              : Icons.do_not_disturb_on,
                          color: profile.disponible ? Colors.green : Colors.red,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          profile.disponible
                              ? 'Vous êtes actuellement EN LIGNE'
                              : 'Vous êtes actuellement HORS LIGNE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: profile.disponible
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bouton Switch principal (Fonctionnalité clé demandée à Maniga)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: profile.disponible
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: Icon(
                        profile.disponible
                            ? Icons.power_settings_new
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        profile.disponible
                            ? 'Passer Hors Ligne'
                            : 'Passer En Ligne',
                      ),
                      onPressed: () async {
                        await ref
                            .read(professionalProfileProvider.notifier)
                            .toggleAvailability();
                      },
                    ),
                  ],
                ),
              ),

              // --- SECTION 2 : TITRE DES DEMANDES D'INTERVENTION ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, color: Color(0xFF0F5234)),
                    const SizedBox(width: 8),
                    const Text(
                      'Demandes d\'intervention reçues',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // --- SECTION 3 : LISTE DES DEMANDES EN TEMPS RÉEL ---
              Expanded(
                child: requestsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Center(
                    child: Text('Erreur lors du chargement des demandes.'),
                  ),
                  data: (requests) {
                    if (requests.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucune demande reçue pour le moment.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return _buildRequestCard(context, ref, request);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- COMPOSANT : CARTE D'UNE DEMANDE D'INTERVENTION ---
  Widget _buildRequestCard(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) {
    // Attribution dynamique d'une couleur selon le statut
    Color statusColor;
    String statusText;

    switch (request.status) {
      case RequestStatus.enAttente:
        statusColor = Colors.orange;
        statusText = 'En attente';
        break;
      case RequestStatus.acceptee:
        statusColor = Colors.blue;
        statusText = 'Acceptée';
        break;
      case RequestStatus.refusee:
        statusColor = Colors.grey;
        statusText = 'Refusée';
        break;
      case RequestStatus.terminee:
        statusColor = Colors.green;
        statusText = 'Terminée';
        break;
      default:
        statusColor = Colors.black;
        statusText = 'Inconnu';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              style: const TextStyle(color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // --- ACTIONS (Accepter / Refuser / Terminer) ---
            if (request.status == RequestStatus.enAttente)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ref
                        .read(requestActionsProvider)
                        .updateRequestStatus(request.id, RequestStatus.refusee),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Refuser'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(requestActionsProvider)
                        .updateRequestStatus(
                          request.id,
                          RequestStatus.acceptee,
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5234),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accepter'),
                  ),
                ],
              )
            else if (request.status == RequestStatus.acceptee)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref
                      .read(requestActionsProvider)
                      .updateRequestStatus(request.id, RequestStatus.terminee),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Marquer comme Terminée'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
