import 'package:cloud_firestore/cloud_firestore.dart';

/// Chemin de la sous-collection des messages d'une demande.
///
/// On suit la proposition de la rencontre d'équipe (« Améliorations
/// futures », section 1) : les messages vivent sous la demande, ce qui évite
/// une collection racine supplémentaire et rend le fil naturellement lié au
/// contexte de la mission.
///
///     requests/{requestId}/messages/{messageId}
String messagesCollectionPath(String requestId) =>
    'requests/$requestId/messages';

/// Un message de chat entre le client et le professionnel d'une demande.
///
/// Les messages sont immuables : la lecture est gérée par
/// [ChatThread.clientLastReadAt] / [ChatThread.proLastReadAt] posés sur la
/// demande, donc aucune écriture n'est nécessaire ici.
class ChatMessage {
  final String id;
  final String requestId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  bool isMine(String uid) => senderId == uid;

  factory ChatMessage.fromMap(
    String requestId,
    String id,
    Map<String, dynamic> map,
  ) {
    return ChatMessage(
      id: id,
      requestId: requestId,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}