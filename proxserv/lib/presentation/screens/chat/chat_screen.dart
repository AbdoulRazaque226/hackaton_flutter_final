import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/chat_providers.dart';
import '../../../application/providers/directory_providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/service_request.dart';
import '../../widgets/empty_state.dart';

/// Fil de discussion rattaché à une demande.
///
/// La liste est ancrée en bas (`reverse: true`) : les messages arrivent alors
/// naturellement au-dessus de la zone de saisie, sans gestion manuelle du
/// défilement à chaque nouveau message.
class ChatScreen extends ConsumerStatefulWidget {
  final String requestId;

  const ChatScreen({super.key, required this.requestId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Ouvrir le fil vaut lecture : on positionne la curse de lecture.
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      ref
          .read(chatActionsProvider)
          .markAsRead(widget.requestId, user.role)
          .ignore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    _controller.clear();
    setState(() => _sending = true);

    try {
      await ref
          .read(chatActionsProvider)
          .sendMessage(
            requestId: widget.requestId,
            senderId: user.uid,
            text: text,
          );
    } catch (error) {
      // Le message n'est pas parti : on le rend à l'utilisateur plutôt que de
      // le laisser disparaître silencieusement.
      _controller.text = text;
      if (mounted) {
        final loc = AppLocalizations.fromContext(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.text('Envoi impossible : $error', 'Unable to send: $error'),
            ),
            action: SnackBarAction(
              label: loc.text('Réessayer', 'Retry'),
              onPressed: _send,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final request = ref.watch(requestByIdProvider(widget.requestId)).value;
    final loc = AppLocalizations.fromContext(context);

    // Garde : seuls le client et le professionnel de la demande ont accès au
    // fil. Les règles Firestore refusent aussi l'écriture, mais l'écran ne doit
    // pas laisser croire le contraire.
    if (user != null &&
        request != null &&
        user.uid != request.clientId &&
        user.uid != request.professionalId) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.text('Conversation', 'Conversation'))),
        body: EmptyState(
          icon: Icons.lock_outline,
          title: loc.text('Accès refusé', 'Access denied'),
          detail: loc.text(
            'Cette conversation ne vous concerne pas.',
            'This conversation is not associated with your account.',
          ),
        ),
      );
    }

    final role = user?.role ?? UserRole.client;
    final counterpart = request == null
        ? loc.text('Conversation', 'Conversation')
        : role == UserRole.professionnel
        ? (request.clientName.isNotEmpty
              ? request.clientName
              : loc.text('Client', 'Client'))
        : (_proName(request) ?? loc.text('Professionnel', 'Professional'));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(counterpart, style: const TextStyle(fontSize: 16)),
            if (request != null)
              Text(
                loc.metierLabel(request.metier),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (request != null) _ContextHeader(request: request),
          Expanded(child: _buildMessages(role, loc)),
          _Composer(
            controller: _controller,
            sending: _sending,
            onSend: _send,
            loc: loc,
          ),
        ],
      ),
    );
  }

  /// Nom du professionnel pour l'en-tête (côté client).
  String? _proName(ServiceRequest request) {
    final names = ref.watch(proDirectoryProvider).value;
    final name = names?[request.professionalId];
    return (name?.isNotEmpty ?? false) ? name : null;
  }

  Widget _buildMessages(UserRole role, AppLocalizations loc) {
    final messagesAsync = ref.watch(messagesProvider(widget.requestId));

    if (messagesAsync.hasError) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: loc.text('Messages indisponibles', 'Messages unavailable'),
        detail: loc.text(
          'Vérifiez votre connexion internet.',
          'Check your internet connection.',
        ),
      );
    }

    final messages = messagesAsync.value;
    if (messages == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return EmptyState(
        icon: Icons.waving_hand_outlined,
        title: loc.text('Démarrez la conversation', 'Start the conversation'),
        detail: loc.text(
          'Précisez l\'adresse, le créneau qui vous convient, ou toute information utile sur la tâche.',
          'Share the address, a suitable time, or any useful information about the job.',
        ),
      );
    }

    final uid = ref.read(currentUserProvider).value?.uid ?? '';

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _Bubble(message: message, mine: message.isMine(uid));
      },
    );
  }
}

/// Rappel du contexte : de quoi parle la conversation.
class _ContextHeader extends StatelessWidget {
  final ServiceRequest request;

  const _ContextHeader({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.fromContext(context);
    final closed =
        request.status == RequestStatus.terminee ||
        request.status == RequestStatus.refusee ||
        request.status == RequestStatus.annulee ||
        request.status == RequestStatus.sansReponse;

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.description.isNotEmpty
                ? request.description
                : loc.text(
                    'Demande ${loc.metierLabel(request.metier).toLowerCase()}',
                    '${loc.metierLabel(request.metier)} request',
                  ),
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (closed) ...[
            const SizedBox(height: 4),
            Text(
              loc.text(
                'Demande clôturée — la conversation reste consultable.',
                'Request closed; this conversation remains available.',
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = mine
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = mine
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final AppLocalizations loc;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: loc.text('Votre message…', 'Your message…'),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              tooltip: loc.text('Envoyer', 'Send'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
