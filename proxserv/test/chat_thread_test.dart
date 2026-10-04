import 'package:flutter_test/flutter_test.dart';
import 'package:proxserv/application/providers/history_providers.dart';
import 'package:proxserv/data/models/app_user.dart';
import 'package:proxserv/data/models/chat_message.dart';
import 'package:proxserv/data/models/chat_thread.dart';
import 'package:proxserv/data/models/enums.dart';
import 'package:proxserv/data/models/service_request.dart';

void main() {
  final base = DateTime(2026, 1, 10, 9);

  ServiceRequest request({
    RequestStatus status = RequestStatus.enAttente,
    String clientId = 'client-1',
    String professionalId = 'pro-1',
  }) {
    return ServiceRequest(
      id: 'r1',
      clientId: clientId,
      clientName: 'Aya Traoré',
      professionalId: professionalId,
      metier: Metier.plombier,
      description: 'Fuite sous l\'évier',
      latitude: 5.36,
      longitude: -3.99,
      status: status,
      createdAt: base,
      updatedAt: base,
    );
  }

  ChatThread thread({
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    DateTime? clientLastReadAt,
    DateTime? proLastReadAt,
  }) {
    return ChatThread(
      requestId: 'r1',
      request: request(),
      lastMessage: 'Bonjour',
      lastMessageAt: lastMessageAt,
      lastMessageSenderId: lastMessageSenderId,
      clientLastReadAt: clientLastReadAt,
      proLastReadAt: proLastReadAt,
    );
  }

  group('ChatThread.isUnreadFor', () {
    test('un fil sans message n\'est jamais non lu', () {
      expect(thread().isUnreadFor('pro-1', UserRole.client), isFalse);
    });

    test('son propre message ne se marque pas non lu', () {
      final t = thread(lastMessageAt: base, lastMessageSenderId: 'client-1');
      expect(t.isUnreadFor('client-1', UserRole.client), isFalse);
    });

    test('un message reçu sans curseur de lecture est non lu', () {
      final t = thread(lastMessageAt: base, lastMessageSenderId: 'pro-1');
      expect(t.isUnreadFor('client-1', UserRole.client), isTrue);
    });

    test('un message antérieur au curseur de lecture est déjà vu', () {
      final t = thread(
        lastMessageAt: base,
        lastMessageSenderId: 'pro-1',
        clientLastReadAt: base.add(const Duration(minutes: 5)),
      );
      expect(t.isUnreadFor('client-1', UserRole.client), isFalse);
    });

    test('un message postérieur au curseur de lecture est non lu', () {
      final t = thread(
        lastMessageAt: base.add(const Duration(hours: 2)),
        lastMessageSenderId: 'pro-1',
        clientLastReadAt: base,
      );
      expect(t.isUnreadFor('client-1', UserRole.client), isTrue);
    });

    test('chaque rôle lit son propre curseur', () {
      final t = thread(
        lastMessageAt: base,
        lastMessageSenderId: 'client-1',
        // Le client a lu jusqu'au message ; le professionnel n'a lu que la
        // conversation précédente.
        clientLastReadAt: base,
        proLastReadAt: base.subtract(const Duration(hours: 1)),
      );
      expect(t.isUnreadFor('client-1', UserRole.client), isFalse);
      expect(t.isUnreadFor('pro-1', UserRole.professionnel), isTrue);
    });
  });

  group('ChatMessage.isMine', () {
    test('compare l\'auteur au compte connecté', () {
      final message = ChatMessage(
        id: 'm1',
        requestId: 'r1',
        senderId: 'pro-1',
        text: 'Bonjour',
        createdAt: base,
      );
      expect(message.isMine('pro-1'), isTrue);
      expect(message.isMine('client-1'), isFalse);
    });
  });

  group('Répartition de l\'historique', () {
    final all = [
      request(status: RequestStatus.enAttente),
      request(status: RequestStatus.acceptee),
      request(status: RequestStatus.terminee),
      request(status: RequestStatus.refusee),
    ];

    test('« à compléter » regroupe en attente et acceptée', () {
      expect(all.pending.map((r) => r.status), [
        RequestStatus.enAttente,
        RequestStatus.acceptee,
      ]);
    });

    test('« complétées » regroupe terminée et refusée', () {
      expect(all.closed.map((r) => r.status), [
        RequestStatus.terminee,
        RequestStatus.refusee,
      ]);
    });

    test('une liste vide ne lève pas', () {
      expect(const <ServiceRequest>[].pending, isEmpty);
      expect(const <ServiceRequest>[].closed, isEmpty);
    });
  });
}
