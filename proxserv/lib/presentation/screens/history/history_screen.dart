import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/chat_providers.dart';
import '../../../application/providers/directory_providers.dart';
import '../../../application/providers/history_providers.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/chat_thread.dart';
import '../../navigation/chat_route.dart';
import '../../widgets/empty_state.dart';
import 'request_tile.dart';

/// Onglet « Historique » du dashboard.
///
/// Même contenu pour le client et le professionnel, réparti en deux
/// sous-onglets selon l'état de la demande : ce qu'il reste à faire, et ce
/// qui est clos.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historique'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'À compléter'),
              Tab(text: 'Complétées'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HistoryList(closed: false),
            _HistoryList(closed: true),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  /// `false` → demandes en attente ou acceptées ; `true` → terminées ou
  /// refusées.
  final bool closed;

  const _HistoryList({required this.closed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRequestsProvider);
    final user = ref.watch(currentUserProvider).value;

    if (requestsAsync.hasError) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Chargement impossible',
        detail: 'Vérifiez votre connexion internet.',
        actionLabel: 'Réessayer',
        onAction: () => ref.invalidate(myRequestsProvider),
      );
    }

    final all = requestsAsync.value;
    if (all == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final requests = closed ? all.closed : all.pending;

    if (requests.isEmpty) {
      return EmptyState(
        icon: closed ? Icons.task_alt : Icons.assignment_outlined,
        title: closed
            ? 'Aucune intervention terminée'
            : 'Rien à compléter',
        detail: closed
            ? 'Vos interventions terminées apparaîtront ici.'
            : 'Vous n\'avez aucune demande en attente ou acceptée.',
      );
    }

    // Les fils de discussion servent uniquement à savoir si des messages non
    // lus attendent l'utilisateur sur cette demande.
    final threads = {
      for (final thread in ref.watch(myChatThreadsProvider).value ??
          const <ChatThread>[])
        thread.requestId: thread,
    };
    final proNames = ref.watch(proDirectoryProvider).value ?? const {};
    final uid = user?.uid ?? '';

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return RequestTile(
          request: request,
          role: user?.role ?? UserRole.client,
          proName: proNames[request.professionalId],
          unread: threads[request.id]?.isUnreadFor(uid, user?.role ?? UserRole.client) ?? false,
          onTap: () => context.push(chatRoutePath(request.id)),
        );
      },
    );
  }
}