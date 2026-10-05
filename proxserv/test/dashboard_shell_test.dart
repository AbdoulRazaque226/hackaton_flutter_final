import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
      proDirectoryProvider.overrideWith(
        (ref) async => {'pro-1': 'Kouassi Yao'},
      ),
      userPreferencesProvider.overrideWith(
        (ref) => Stream.value(const <String, dynamic>{}),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('fr'),
      supportedLocales: [Locale('fr')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DashboardShell(
        home: Scaffold(body: Center(child: Text('ACCUEIL'))),
      ),
    ),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  final shell = find.byWidgetPredicate(
    (widget) => widget is Scaffold && widget.drawer != null,
  );
  tester.state<ScaffoldState>(shell.first).openDrawer();
  await tester.pumpAndSettle();
}

Future<void> _selectDrawerItem(WidgetTester tester, String label) async {
  await _openDrawer(tester);
  await tester.tap(
    find.descendant(of: find.byType(Drawer), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un changement de query parameter synchronise l’onglet actif', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;

    final router = GoRouter(
      initialLocation: '/client/home',
      routes: [
        GoRoute(
          path: '/client/home',
          builder: (context, state) => DashboardShell(
            home: Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => context.go('/client/home?tab=explore'),
                  child: const Text('Go to Explore'),
                ),
              ),
            ),
            initialIndex: state.uri.queryParameters['tab'] == 'explore' ? 1 : 0,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(_client())),
          professionalProfileProvider.overrideWith(ProfessionalNotifier.new),
          myRequestsProvider.overrideWith((ref) => Stream.value(const [])),
          myChatThreadsProvider.overrideWith((ref) => Stream.value(const [])),
          proDirectoryProvider.overrideWith((ref) async => const {}),
          userPreferencesProvider.overrideWith(
            (ref) => Stream.value(const <String, dynamic>{}),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DashboardShell), findsOneWidget);

    await tester.tap(find.text('Go to Explore'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to explore professionals.'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('le shell respecte les breakpoints de navigation', (
    tester,
  ) async {
    for (final (width, expectsDrawer, expectsExtendedRail) in [
      (599.0, true, false),
      (600.0, false, false),
      (839.0, false, false),
      (840.0, false, true),
    ]) {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;

      await tester.pumpWidget(_dashboard());
      await tester.pumpAndSettle();

      final hasDrawer = tester
          .widgetList<Scaffold>(find.byType(Scaffold))
          .any((scaffold) => scaffold.drawer != null);
      expect(hasDrawer, expectsDrawer, reason: 'width: $width');
      expect(find.byType(NavigationBar), findsNothing, reason: 'width: $width');
      final rail = find.byType(NavigationRail);
      expect(rail, expectsDrawer ? findsNothing : findsOneWidget);
      if (expectsExtendedRail) {
        expect(tester.widget<NavigationRail>(rail).extended, isTrue);
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('la coquille expose les cinq onglets', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    await tester.pumpWidget(_dashboard());
    await tester.pumpAndSettle();

    await _openDrawer(tester);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Explorer'), findsOneWidget);
    expect(find.text('Demandes'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Paramètres'), findsOneWidget);

    // Le contenu « Accueil » fourni par l'appelant est bien monté.
    expect(find.text('ACCUEIL'), findsOneWidget);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('chaque onglet affiche son contenu', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    await tester.pumpWidget(_dashboard());
    await tester.pumpAndSettle();

    await _selectDrawerItem(tester, 'Explorer');
    expect(
      find.text('Connectez-vous pour explorer les professionnels.'),
      findsOneWidget,
    );

    await _selectDrawerItem(tester, 'Messages');
    expect(find.text('Aucune conversation'), findsOneWidget);

    await _selectDrawerItem(tester, 'Demandes');
    expect(find.text('À compléter'), findsOneWidget);
    expect(find.text('Complétées'), findsOneWidget);

    await _selectDrawerItem(tester, 'Profil');
    expect(find.textContaining('Profil complété à'), findsOneWidget);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('le passage à l\'onglet Demandes affiche la demande', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    await tester.pumpWidget(_dashboard(requests: [_request()]));
    await tester.pumpAndSettle();

    await _selectDrawerItem(tester, 'Demandes');

    expect(find.text('Plombier'), findsWidgets);
    expect(find.textContaining('Fuite sous l\'évier'), findsOneWidget);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('une demande terminée bascule dans « Complétées »', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    await tester.pumpWidget(
      _dashboard(requests: [_request(status: RequestStatus.terminee)]),
    );
    await tester.pumpAndSettle();

    await _selectDrawerItem(tester, 'Demandes');

    // Onglet « À compléter » : rien à afficher.
    expect(find.text('Rien à compléter'), findsOneWidget);

    await tester.tap(find.text('Complétées'));
    await tester.pumpAndSettle();

    expect(find.text('Plombier'), findsWidgets);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
