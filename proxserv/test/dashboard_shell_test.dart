import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxserv/application/providers/app_providers.dart';
import 'package:proxserv/application/providers/chat_providers.dart';
import 'package:proxserv/application/providers/directory_providers.dart';
import 'package:proxserv/application/providers/history_providers.dart';
import 'package:proxserv/application/providers/settings_providers.dart';
import 'package:proxserv/data/models/app_user.dart';
import 'package:proxserv/data/models/enums.dart';
import 'package:proxserv/data/models/service_request.dart';
import 'package:proxserv/presentation/screens/dashboard/dashboard_shell.dart';

/// Rendu de la coquille du dashboard sans Firebase : tous les providers lus par
/// les cinq onglets sont remplacés par des valeurs fixes.
///
/// Le test sert de garde-fou sur ce qui compte réellement : que le tableau de
/// bord se construise et que la navigation entre onglets fonctionne. Un
/// `IndexedStack` construisant tous ses enfants, une exception dans un seul
/// onglet ferait échouer l'ensemble — c'est exactement ce qu'on veut attraper ici.
AppUser _client() => const AppUser(
      uid: 'client-1',
      email: 'aya@example.com',
      displayName: 'Aya Traoré',
      phone: '0700000000',
      role: UserRole.client,
    );

ServiceRequest _request({
  RequestStatus status = RequestStatus.enAttente,
  String clientName = 'Aya Traoré',
}) {
  final date = DateTime(2026, 1, 10, 9);
  return ServiceRequest(
    id: 'r1',
    clientId: 'client-1',
    clientName: clientName,
    professionalId: 'pro-1',
    metier: Metier.plombier,
    description: 'Fuite sous l\'évier de la cuisine',
    latitude: 5.36,
    longitude: -3.99,
    status: status,
    createdAt: date,
    updatedAt: date,
  );
}

Widget _dashboard({
  List<ServiceRequest> requests = const [],
  List<Object> threads = const [],
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => Stream.value(_client())),
      // Le vrai notifier est utilisable ici : son initialisation n'écoute
      // Firestore que pour un rôle « professionnel », or nos comptes de test
      // sont des clients.
      professionalProfileProvider.overrideWith(ProfessionalNotifier.new),
      myRequestsProvider.overrideWith((ref) => Stream.value(requests)),
      // Le type exact n'importe pas ici : la coquille ne lit ce provider que
      // pour dériver le badge de non-lus, alimenté par une liste vide.
      myChatThreadsProvider.overrideWith((ref) => Stream.value(threads.cast())),
      proDirectoryProvider.overrideWith((ref) async => {'pro-1': 'Kouassi Yao'}),
      userPreferencesProvider
          .overrideWith((ref) => Stream.value(const <String, dynamic>{})),
    ],
    child: const MaterialApp(
      home: DashboardShell(
        home: Scaffold(body: Center(child: Text('ACCUEIL'))),
      ),
    ),
  );
}

void main() {
  testWidgets('la coquille expose les cinq onglets', (tester) async {
    await tester.pumpWidget(_dashboard());
    await tester.pumpAndSettle();

    // Les libellés de la barre de navigation sont toujours affichés.
    // On ne contrôle pas les icônes : une NavigationBar ne construit que
    // l'icône de la destination sélectionnée.
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Le contenu « Accueil » fourni par l'appelant est bien monté.
    expect(find.text('ACCUEIL'), findsOneWidget);
  });

  testWidgets('chaque onglet affiche son contenu', (tester) async {
    // L'IndexedStack ne construit pas qu'un onglet à la fois : une exception
    // dans l'un d'eux ferait échouer l'ensemble. On visite donc les cinq.
    await tester.pumpWidget(_dashboard());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune conversation'), findsOneWidget);

    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();
    expect(find.text('À compléter'), findsOneWidget);
    expect(find.text('Complétées'), findsOneWidget);

    await tester.tap(find.text('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Profil complété à'), findsOneWidget);
  });

  testWidgets('le passage à l\'onglet Historique affiche la demande', (tester) async {
    await tester.pumpWidget(
      _dashboard(requests: [_request()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Plombier'), findsWidgets);
    expect(find.textContaining('Fuite sous l\'évier'), findsOneWidget);
  });

  testWidgets('une demande terminée bascule dans « Complétées »', (tester) async {
    await tester.pumpWidget(
      _dashboard(requests: [_request(status: RequestStatus.terminee)]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    // Onglet « À compléter » : rien à afficher.
    expect(find.text('Rien à compléter'), findsOneWidget);

    await tester.tap(find.text('Complétées'));
    await tester.pumpAndSettle();

    expect(find.text('Plombier'), findsWidgets);
  });
}