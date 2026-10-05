import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:proxserv/core/utils/problem_classifier.dart';
import 'package:proxserv/data/models/enums.dart';
import 'package:proxserv/presentation/screens/client_home_screen.dart';

void main() {
  test('classifies common French and English needs deterministically', () {
    expect(classifyProblem("J'ai une fuite d'eau"), Metier.plombier);
    expect(classifyProblem('prise électrique cassée'), Metier.electricien);
    expect(classifyProblem('A broken electrical outlet'), Metier.electricien);
    expect(classifyProblem('Ma porte est cassée'), Metier.menuisier);
    expect(classifyProblem('Je veux fabriquer une armoire'), Metier.menuisier);
    expect(classifyProblem('Je veux repeindre mon salon'), Metier.peintre);
    expect(classifyProblem('Un mur à peindre'), Metier.peintre);
    expect(classifyProblem('Construire un mur en briques'), Metier.macon);
    expect(classifyProblem('My appliance is broken'), Metier.reparateur);
    expect(classifyProblem('Nettoyer ma maison'), Metier.nettoyage);
  });

  test('leaves empty and unmatched needs ambiguous', () {
    expect(classifyProblem(''), isNull);
    expect(classifyProblem('J’ai besoin d’aide'), isNull);
  });

  test(
    'home trade selection produces a GoRouter Explore URL with the filter',
    () {
      final uri = Uri.parse(clientHomeExploreUri(metier: Metier.plombier));
      expect(uri.path, '/client/home');
      expect(uri.queryParameters['tab'], 'explore');
      expect(uri.queryParameters['metier'], 'plombier');
    },
  );

  testWidgets('tapping a home trade opens its filtered Explore route', (
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
          builder: (context, state) {
            final metier = state.uri.queryParameters['metier'];
            return metier == null
                ? const ClientHomeScreen()
                : Scaffold(
                    body: Text(
                      'results:${state.uri.queryParameters['tab']}:$metier',
                    ),
                  );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(ClientHomeScreen), findsOneWidget);
    expect(find.text('Choose a trade'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Plumber'),
      find.byType(CustomScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plumber'));
    await tester.pumpAndSettle();

    expect(find.text('results:explore:plombier'), findsOneWidget);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
