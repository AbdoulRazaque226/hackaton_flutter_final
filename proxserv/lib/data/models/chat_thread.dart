import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_user.dart';
import 'service_request.dart';

/// Un fil de discussion rattaché à une demande.
///
/// Le fil n'est pas une entité Firestore à part : c'est la demande elle-même
/// augmentée des quelques champs dénormalisés qui permettent d'afficher la
/// liste des conversations (dernier message, position de lecture) sans lire
/// chaque sous-collection `messages`.
///
/// Champs dénormalisés attendus sur le document `requests/{id}` :
///   lastMessage, lastMessageAt, lastMessageSenderId,
///   clientLastReadAt, proLastReadAt
class ChatThread {
  final String requestId;
  final ServiceRequest request;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final DateTime? clientLastReadAt;
  final DateTime? proLastReadAt;

  const ChatThread({
    required this.requestId,
    required this.request,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.clientLastReadAt,
    this.proLastReadAt,
  });

  /// Le fil n'apparaît dans la liste que s'il contient au moins un message.
  bool get hasMessages => lastMessageAt != null;

  /// Timestamp jusqu'auquel l'utilisateur a lu, selon son rôle.
  DateTime? lastReadAtFor(UserRole role) {
    switch (role) {
      case UserRole.client:
        return clientLastReadAt;
      case UserRole.professionnel:
        return proLastReadAt;
      case UserRole.admin:
        return null;
    }
  }

  /// Vrai si [uid] a des messages non lus. Le dernier message doit venir de
  /// l'interlocuteur : on ne se marque pas soi-même « non lu ».
  bool isUnreadFor(String uid, UserRole role) {
    final at = lastMessageAt;
    if (at == null || lastMessageSenderId == uid) return false;
    final read = lastReadAtFor(role);
    return read == null || at.isAfter(read);
  }

  /// Identifiant de l'interlocuteur (l'autre partie de la demande).
  String otherPartyUid(String uid) =>
      request.clientId == uid ? request.professionalId : request.clientId;

  factory ChatThread.fromRequestDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ChatThread(
      requestId: doc.id,
      request: ServiceRequest.fromMap(doc.id, {...data, 'id': doc.id}),
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      clientLastReadAt: (data['clientLastReadAt'] as Timestamp?)?.toDate(),
      proLastReadAt: (data['proLastReadAt'] as Timestamp?)?.toDate(),
    );
  }
}
