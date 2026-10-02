import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_thread.dart';
import '../../data/models/service_request.dart';
import 'app_providers.dart';

/// Les fils de discussion de l'utilisateur connecté, du plus récent au plus
/// ancien.
///
/// On interroge `requests` en filtrant sur le rôle (ce sont les documents qui
/// portent les champs dénormalisés du chat) et on trie **en Dart**, pas avec
/// un `orderBy` Firestore : un `where` + `orderBy` sur un champ différent
/// impose un index composite à déployer sur la console Firebase, sans quoi la
/// requête échoue. Le tri côté client évite cette dépendance pour le MVP.
final myChatThreadsProvider = StreamProvider<List<ChatThread>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);

  final field = switch (user.role) {
    UserRole.professionnel => 'professionalId',
    UserRole.client => 'clientId',
    UserRole.admin => 'clientId',
  };

  return ref
      .watch(firestoreProvider)
      .collection('requests')
      .where(field, isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final threads = snapshot.docs
            .map(ChatThread.fromRequestDoc)
            .where((thread) => thread.hasMessages)
            .toList();
        threads.sort(
          (a, b) => b.lastMessageAt!.compareTo(a.lastMessageAt!),
        );
        return threads;
      });
});

/// Nombre total de conversations non lues — alimente le badge de l'onglet
/// Chat. Volontairement limité au chat : les notifications plus larges
/// (nouvelle demande, changement de statut) relèvent du travail de Maniga.
final unreadChatCountProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider).value;
  final threads = ref.watch(myChatThreadsProvider).value;
  if (user == null || threads == null) return 0;
  return threads.where((t) => t.isUnreadFor(user.uid, user.role)).length;
});

/// La demande à laquelle appartient un fil — sert d'en-tête du thread
/// (métier, description, nom de l'interlocuteur).
final requestByIdProvider =
    StreamProvider.family<ServiceRequest?, String>((ref, requestId) {
  return ref
      .watch(firestoreProvider)
      .collection('requests')
      .doc(requestId)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? ServiceRequest.fromMap(requestId, {
                ...snapshot.data()!,
                'id': requestId,
              })
            : null,
      );
});

/// Messages d'un fil, du plus ancien au plus récent.
final messagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, requestId) {
  return ref.watch(chatActionsProvider).watchMessages(requestId);
});

/// Actions d'écriture sur les messages.
class ChatActions {
  ChatActions(this._firestore);

  final FirebaseFirestore _firestore;

  /// Flux des messages d'un fil, du plus ancien au plus récent.
  ///
  /// `orderBy` seul sur la sous-collection : index mono-champ automatique, rien
  /// à déployer. La limite évite de charger indéfiniment une longue
  /// conversation.
  Stream<List<ChatMessage>> watchMessages(String requestId) {
    return _firestore
        .collection(messagesCollectionPath(requestId))
        .orderBy('createdAt')
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(requestId, doc.id, doc.data()))
              .toList(),
        );
  }

  /// Envoie un message et met à jour, dans la même écriture atomique, les
  /// champs dénormalisés du fil (dernier message + horodatage). Sans cela le
  /// message resterait invisible dans la liste des conversations.
  Future<void> sendMessage({
    required String requestId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final batch = _firestore.batch();
    final messageRef = _firestore
        .collection(messagesCollectionPath(requestId))
        .doc();
    final now = FieldValue.serverTimestamp();

    batch.set(messageRef, {
      'senderId': senderId,
      'text': trimmed,
      'createdAt': now,
    });
    batch.update(_firestore.collection('requests').doc(requestId), {
      'lastMessage': trimmed,
      'lastMessageAt': now,
      'lastMessageSenderId': senderId,
    });

    await batch.commit();
  }

  /// Marque un fil comme lu pour [role].
  ///
  /// On écrit un timestamp de lecture plutôt qu'un compteur de non-lus : deux
  /// envois simultanés ne peuvent alors pas écraser un compteur (race
  /// classique du read-modify-write).
  Future<void> markAsRead(String requestId, UserRole role) {
    final field = switch (role) {
      UserRole.client => 'clientLastReadAt',
      UserRole.professionnel => 'proLastReadAt',
      UserRole.admin => 'clientLastReadAt',
    };
    return _firestore.collection('requests').doc(requestId).update({
      field: FieldValue.serverTimestamp(),
    });
  }
}

final chatActionsProvider = Provider<ChatActions>(
  (ref) => ChatActions(ref.watch(firestoreProvider)),
);