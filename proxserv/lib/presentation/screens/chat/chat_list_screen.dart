import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/chat_providers.dart';
import '../../../application/providers/directory_providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/chat_thread.dart';
import '../../navigation/chat_route.dart';
import '../../widgets/empty_state.dart';
import '../dashboard/dashboard_menu.dart';
import '../register_screen.dart' show metierIcon;

/// Onglet « Chat » du dashboard : liste des conversations.
///
/// Il n'existe pas de chat global : chaque fil est rattaché à une demande, et
/// la conversation se démarre donc depuis une carte de l'historique ou depuis
/// la fiche d'un professionnel. L'écran liste simplement les fils où
/// l'utilisateur est déjà engagé.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(myChatThreadsProvider);
    final user = ref.watch(currentUserProvider).value;
    final loc = AppLocalizations.fromContext(context);

    return Scaffold(
      appBar: AppBar(
        leading: dashboardMenuLeading(context),
        title: Text(loc.messagesTab),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Réessayer',
            onPressed: () => ref.invalidate(myChatThreadsProvider),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (threadsAsync.hasError) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: loc.text(
                'Chargement impossible',
                'Unable to load messages',
              ),
              detail: loc.text(
                'Vérifiez votre connexion internet.',
                'Check your internet connection.',
              ),
            );
          }

          final threads = threadsAsync.value;
          if (threads == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (threads.isEmpty) {
            return EmptyState(
              icon: Icons.forum_outlined,
              title: loc.text('Aucune conversation', 'No conversations'),
              detail: loc.text(
                'Ouvrez une demande depuis Demandes pour discuter avec le professionnel.',
                'Open a request from Requests to chat with the professional.',
              ),
            );
          }

          final proNames = ref.watch(proDirectoryProvider).value ?? const {};
          final uid = user?.uid ?? '';
          final role = user?.role ?? UserRole.client;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: threads.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return _ThreadTile(
                thread: thread,
                counterpart: _counterpartName(thread, role, proNames, loc),
                unread: thread.isUnreadFor(uid, role),
                loc: loc,
                onTap: () => context.push(chatRoutePath(thread.requestId)),
              );
            },
          );
        },
      ),
    );
  }
}

/// Nom affiché pour l'interlocuteur, selon le rôle de l'utilisateur.
String _counterpartName(
  ChatThread thread,
  UserRole role,
  Map<String, String> proNames,
  AppLocalizations loc,
) {
  if (role == UserRole.professionnel) {
    final name = thread.request.clientName;
    return name.isNotEmpty ? name : loc.text('Client', 'Client');
  }
  final name = proNames[thread.request.professionalId];
  return (name?.isNotEmpty ?? false)
      ? name!
      : loc.text('Professionnel', 'Professional');
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final String counterpart;
  final bool unread;
  final AppLocalizations loc;
  final VoidCallback onTap;

  const _ThreadTile({
    required this.thread,
    required this.counterpart,
    required this.unread,
    required this.loc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = thread.request;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          metierIcon(request.metier),
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              counterpart,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (thread.lastMessageAt != null)
            Text(
              _relativeTime(thread.lastMessageAt!, loc),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${loc.metierLabel(request.metier)} · ${thread.lastMessage ?? ''}',
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: unread
                ? theme.colorScheme.onSurface
                : theme.colorScheme.outline,
            fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// « à l'instant », « il y a 5 min », « 12/03 » — suffisant pour un fil de
/// discussion lié à une intervention.
String _relativeTime(DateTime dt, AppLocalizations loc) {
  final diff = DateTime.now().difference(dt);

  if (diff.inMinutes < 1) return loc.text('à l\'instant', 'just now');
  if (diff.inMinutes < 60) {
    return loc.text(
      'il y a ${diff.inMinutes} min',
      '${diff.inMinutes} min ago',
    );
  }
  if (diff.inHours < 24) {
    return loc.text('il y a ${diff.inHours} h', '${diff.inHours} hr ago');
  }

  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  return '$day/$month';
}
