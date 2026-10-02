import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/app_providers.dart';
import '../../data/models/service_request.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/models/enums.dart';

class ProfessionalDashboardScreen extends ConsumerWidget {
  const ProfessionalDashboardScreen({super.key});

  void _triggerIncomingRequestAlert(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) {
    // Lecture du son de notification
    final player = AudioPlayer();
    player.play(AssetSource('sounds/notification.mp3'));

    // Affichage d'une SnackBar pour notifier l'artisan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nouvelle demande d\'intervention de ${request.clientName} !',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Ouvre le détail de la demande dans un BottomSheet
            _showRequestDetailsBottomSheet(
              context,
              ref,
              request,
              Colors.orange, // Couleur pour "En attente"
              'En attente',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(professionalProfileProvider);
    final requestsAsync = ref.watch(professionalRequestsProvider);

    // Système d'écoute de la notification push pour les demandes d'intervention
    ref.listen<AsyncValue<List<ServiceRequest>>>(
      professionalRequestsProvider,
      (previous, next) {
        // On s'assure que les données sont correctement chargées
        if (next is AsyncData<List<ServiceRequest>>) {
          final nextRequests = next.value;
          final previousRequests = previous?.value ?? [];

          //Filtrer les demandes actuellement "En attente"
          final newPendingRequests = nextRequests.where(
            (req) => req.status == RequestStatus.enAttente
          ).toList();

          //Détecter s'il y a une NOUVELLE demande par rapport à la liste précédente
          if (newPendingRequests.length > previousRequests.where((req) => req.status == RequestStatus.enAttente).length) {
            // Récupérer la demande la plus récente
            final newestRequest = newPendingRequests.last;

            //Déclencher l'alerte sonore et visuelle
            _triggerIncomingRequestAlert(context, ref, newestRequest);
          }
        }
      },
    );

    

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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      clipBehavior: Clip
          .antiAlias, // Assure que l'effet visuel du clic ne dépasse pas des bords de la carte
      child: InkWell(
        onTap: () => _showRequestDetailsBottomSheet(
          context,
          ref,
          request,
          statusColor,
          statusText,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- EN-TÊTE : NOM ET STATUT ---
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
                      maxLines: 1,
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
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
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
              const SizedBox(height: 10),

              // --- DESCRIPTION COMPACTE ---
              Text(
                request.description ?? 'Aucune description fournie',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // --- ADRESSE COMPACTE ---
              // Row(
              //   children: [
              //     Icon(
              //       Icons.location_on,
              //       size: 14,
              //       color: Colors.grey.shade600,
              //     ),
              //     const SizedBox(width: 4),
              //     Expanded(
              //       child: Text(
              //         request.adresse ?? 'Adresse non spécifiée',
              //         style: TextStyle(
              //           fontSize: 12,
              //           color: Colors.grey.shade600,
              //           fontStyle: FontStyle.italic,
              //         ),
              //         maxLines: 1,
              //         overflow: TextOverflow.ellipsis,
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 4),
              // Petit indicateur discret invitant à cliquer
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Voir détails...',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF0F5234),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetailsBottomSheet(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
    Color statusColor,
    String statusText,
  ) {
    final isEnAttente = request.status == RequestStatus.enAttente;

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Permet à la modale de s'adapter si le contenu est long
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            // S'adapte au clavier virtuel ou aux barres de navigation du téléphone
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize
                .min, // La modale prend uniquement la hauteur nécessaire
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Petite barre supérieure de décoration pour la modale
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- TITRE ET STATUT ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Détails de l\'intervention',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F5234),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
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
              const Divider(height: 30),

              // --- NOM DU CLIENT ---
              const Text(
                'Client',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request.clientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // --- ADRESSE D'INTERVENTION ---
              const Text(
                'Adresse d\'intervention',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // --- DESCRIPTION COMPLÈTE ---
              const Text(
                'Description de la panne / demande',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request.description ?? 'Aucune description fournie',
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),

              // --- BOUTONS D'ACTION ---
              if (isEnAttente)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => ref
                            .read(requestActionsProvider)
                            .updateRequestStatus(
                              request.id,
                              RequestStatus.refusee,
                            ),

                        child: const Text(
                          'Refuser la demande',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5234),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => ref
                            .read(requestActionsProvider)
                            .updateRequestStatus(
                              request.id,
                              RequestStatus.acceptee,
                            ),
                        child: const Text(
                          'Accepter',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                )
              else
                //bouton de fermeture si l'intervention est déjà traitée
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  
}
