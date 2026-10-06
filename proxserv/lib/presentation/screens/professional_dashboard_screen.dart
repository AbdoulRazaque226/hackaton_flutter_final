import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../application/providers/app_providers.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../data/models/service_request.dart';
import '../../data/services/location_service.dart';
import 'dashboard/dashboard_menu.dart';
import '../widgets/request_status_style.dart';
import '../widgets/location_settings_prompt.dart';

class ProfessionalDashboardScreen extends ConsumerWidget {
  const ProfessionalDashboardScreen({super.key});

  void _triggerIncomingRequestAlert(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/notification_sound.mp3'));
    } catch (e) {
      debugPrint("Alerte sonore ignorée : $e");
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notification_important,
              color: AppColors.brandAccent,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ' NOUVELLE DEMANDE : Intervention requise de ${request.clientName} !',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.brandPrimary,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OUVRIR',
          textColor: AppColors.brandAccent,
          onPressed: () {
            _showRequestDetailsBottomSheet(
              context,
              ref,
              request,
              AppColors.warning,
              'En attente',
            );
          },
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (context.mounted) {
        _showRequestDetailsBottomSheet(
          context,
          ref,
          request,
          AppColors.warning,
          'En attente',
        );
      }
    });
  }

  int getResponsiveColumnCount(double width) {
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildNotificationBadge(WidgetRef ref) {
    final requestsAsync = ref.watch(professionalRequestsProvider);

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),

      data: (requests) {
        final pendingCount = requests
            .where((req) => req.status == RequestStatus.enAttente)
            .length;

        if (pendingCount == 0) {
          return const Icon(Icons.notifications_none);
        }

        return Badge(
          backgroundColor: AppColors.error,
          label: Text(
            '$pendingCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          child: const Icon(Icons.notifications),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(professionalProfileProvider);
    final requestsAsync = ref.watch(professionalRequestsProvider);

    ref.listen<AsyncValue<List<ServiceRequest>>>(professionalRequestsProvider, (
      previous,
      next,
    ) {
      if (next is AsyncData<List<ServiceRequest>>) {
        final nextRequests = next.value;
        final previousRequests = previous?.value ?? [];

        final newPendingRequests = nextRequests
            .where((req) => req.status == RequestStatus.enAttente)
            .toList();

        if (newPendingRequests.length >
            previousRequests
                .where((req) => req.status == RequestStatus.enAttente)
                .length) {
          final newestRequest = newPendingRequests.last;
          _triggerIncomingRequestAlert(context, ref, newestRequest);
        }
      }
    });

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: dashboardMenuLeading(context),
          title: const Text(
            'Tableau de Bord Artisan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: _buildNotificationBadge(ref),
                tooltip: 'Demandes en attente',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Consultez vos demandes en attente ci-dessous.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
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

            return LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      color: profile.disponible
                          ? AppColors.successContainer
                          : AppColors.errorContainer,
                      child: isLandscape
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatusIndicator(profile.disponible),
                                _buildAvailabilityButton(
                                  context,
                                  ref,
                                  profile.disponible,
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusIndicator(profile.disponible),
                                const SizedBox(height: 12),
                                _buildAvailabilityButton(
                                  context,
                                  ref,
                                  profile.disponible,
                                ),
                              ],
                            ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assignment,
                            color: AppColors.brandPrimary,
                          ),
                          const SizedBox(width: 8),
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

                          return GridView.builder(
                            padding: const EdgeInsets.only(
                              bottom: 16,
                              left: 8,
                              right: 8,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isLandscape
                                      ? 2
                                      : getResponsiveColumnCount(
                                          constraints.maxWidth,
                                        ),
                                  childAspectRatio: isLandscape
                                      ? (constraints.maxWidth > 800 ? 2.5 : 1.7)
                                      : 2.3,
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

  Widget _buildStatusIndicator(bool isDisponible) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDisponible ? Icons.check_circle : Icons.do_not_disturb_on,
          color: isDisponible ? AppColors.success : AppColors.error,
          size: 28,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            isDisponible ? 'En ligne' : 'Hors ligne',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDisponible ? AppColors.success : AppColors.error,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityButton(
    BuildContext context,
    WidgetRef ref,
    bool isDisponible,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisponible ? AppColors.error : AppColors.success,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(isDisponible ? Icons.power_settings_new : Icons.play_arrow),
      label: Text(isDisponible ? 'Passer Hors Ligne' : 'Passer En Ligne'),
      onPressed: () async {
        try {
          await ref
              .read(professionalProfileProvider.notifier)
              .toggleAvailability();
        } on LocationException catch (error) {
          if (context.mounted) {
            await showLocationSettingsPrompt(
              context,
              error,
              ref.read(locationServiceProvider),
            );
          }
        } catch (error) {
          if (context.mounted) {
            final loc = AppLocalizations.fromContext(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  loc.text(
                    'Impossible de modifier votre disponibilité : $error',
                    'Unable to update your availability: $error',
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) {
    final statusColor = RequestStatusStyle.foreground(request.status);
    final statusText = AppLocalizations.fromContext(
      context,
    ).statusLabel(request.status.name);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
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
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: RequestStatusStyle.background(
                          request.status,
                          Theme.of(context).brightness,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            RequestStatusStyle.icon(request.status),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              statusText,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  request.description.isNotEmpty
                      ? request.description
                      : 'Aucune description fournie',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Voir détails...',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.brandPrimary,
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Détails de l'intervention",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
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
                    request.description.isNotEmpty
                        ? request.description
                        : 'Aucune description fournie',
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  if (isEnAttente)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.errorContainer,
                              foregroundColor: AppColors.error,
                              elevation: 0,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              ref
                                  .read(requestActionsProvider)
                                  .updateRequestStatus(
                                    request.id,
                                    RequestStatus.refusee,
                                  );
                              Navigator.pop(context);
                            },
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
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              ref
                                  .read(requestActionsProvider)
                                  .updateRequestStatus(
                                    request.id,
                                    RequestStatus.acceptee,
                                  );
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Accepter',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (request.status == RequestStatus.acceptee ||
                      request.status == RequestStatus.enCours)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final nextStatus =
                              request.status == RequestStatus.acceptee
                              ? RequestStatus.enCours
                              : RequestStatus.terminee;
                          ref
                              .read(requestActionsProvider)
                              .updateRequestStatus(request.id, nextStatus);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          request.status == RequestStatus.acceptee
                              ? Icons.play_arrow
                              : Icons.task_alt,
                        ),
                        label: Text(
                          request.status == RequestStatus.acceptee
                              ? 'Démarrer l’intervention'
                              : 'Marquer comme terminée',
                        ),
                      ),
                    )
                  else
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
      },
    );
  }
}
