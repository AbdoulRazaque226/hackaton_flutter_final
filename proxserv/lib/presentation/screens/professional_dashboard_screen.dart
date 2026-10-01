import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/app_providers.dart';
import '../../data/models/service_request.dart';
import '../../data/models/enums.dart';

class ProfessionalDashboardScreen extends ConsumerWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(professionalProfileProvider);
    final requestsAsync = ref.watch(professionalRequestsProvider);

    // Utilisation de SafeArea pour éviter les encoches (notches) et barres système
    return SafeArea(
      child: Scaffold(
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
            child: SingleChildScrollView(
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

            // LayoutBuilder permet de s'adapter dynamiquement aux contraintes de taille
            return LayoutBuilder(
              builder: (context, constraints) {
                // Détection du mode paysage ou grand écran
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;

                return Column(
                  children: [
                    // --- SECTION 1 : BANDEAU DE DISPONIBILITÉ RÉACTIF ET RESPONSIVE ---
                    Container(
                      width: double
                          .infinity, // Préférable à MediaQuery pour remplir l'espace disponible
                      padding: const EdgeInsets.all(16.0),
                      color: profile.disponible
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: isLandscape
                          ? Row(
                              // En paysage, on met tout sur une ligne pour gagner de l'espace vertical
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatusIndicator(profile.disponible),
                                _buildAvailabilityButton(
                                  ref,
                                  profile.disponible,
                                ),
                              ],
                            )
                          : Column(
                              // En portrait, on garde la structure verticale
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusIndicator(profile.disponible),
                                const SizedBox(height: 12),
                                _buildAvailabilityButton(
                                  ref,
                                  profile.disponible,
                                ),
                              ],
                            ),
                    ),

                    // --- SECTION 2 : TITRE DES DEMANDES D'INTERVENTION ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assignment,
                            color: Color(0xFF0F5234),
                          ),
                          const SizedBox(width: 8),
                          // Flexible empêche le texte de déborder si la police est très grande
                          const Expanded(
                            child: Text(
                              'Demandes d\'intervention reçues',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                          child: Text(
                            'Erreur lors du chargement des demandes.',
                          ),
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

                          // GridView en paysage (2 colonnes) et ListView en portrait (1 colonne)
                          return isLandscape
                              ? GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio:
                                            2.2, // Ajuster selon le contenu de vos cartes
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                      ),
                                  itemCount: requests.length,
                                  itemBuilder: (context, index) {
                                    return _buildRequestCard(
                                      context,
                                      ref,
                                      requests[index],
                                    );
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: requests.length,
                                  itemBuilder: (context, index) {
                                    return _buildRequestCard(
                                      context,
                                      ref,
                                      requests[index],
                                    );
                                  },
                                );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // --- SOUS-COMPOSANTS EXTRAITS POUR CLARIFIER LE CODE ---

  Widget _buildStatusIndicator(bool isDisponible) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDisponible ? Icons.check_circle : Icons.do_not_disturb_on,
          color: isDisponible ? Colors.green : Colors.red,
          size: 28,
        ),
        const SizedBox(width: 10),
        // Flexible ou Text court indispensable pour éviter les crashs d'affichage
        Flexible(
          child: Text(
            isDisponible ? 'En ligne' : 'Hors ligne',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDisponible ? Colors.green.shade900 : Colors.red.shade900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityButton(WidgetRef ref, bool isDisponible) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisponible ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(isDisponible ? Icons.power_settings_new : Icons.play_arrow),
      label: Text(isDisponible ? 'Passer Hors Ligne' : 'Passer En Ligne'),
      onPressed: () async {
        await ref
            .read(professionalProfileProvider.notifier)
            .toggleAvailability();
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) {
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
                Expanded(
                  child: Text(
                    request.clientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
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
