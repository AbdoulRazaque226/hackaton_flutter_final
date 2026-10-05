import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:proxserv/presentation/screens/public_landing_screen.dart';

import 'package:proxserv/core/theme/app_theme.dart';

void main() {
  testWidgets(
    'public landing stays within mobile, tablet, and desktop widths',
    (tester) async {
      for (final width in [360.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
        tester.view
          ..physicalSize = Size(width, 900)
          ..devicePixelRatio = 1;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const PublicLandingScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'width: $width');
        expect(
          find.byKey(const ValueKey('public-home-hero-image')),
          findsOneWidget,
          reason: 'hero photo should render at width: $width',
        );
        final heroImage = tester.widget<Image>(
          find.byKey(const ValueKey('public-home-hero-image')),
        );
        expect(
          (heroImage.image as AssetImage).assetName,
          'assets/images/hero/hero_home.jpg',
        );
        expect(heroImage.fit, BoxFit.cover);
        final heroBounds = tester.getRect(
          find.byKey(const ValueKey('public-home-hero-card')),
        );
        final imageBounds = tester.getRect(
          find.byKey(const ValueKey('public-home-hero-image')),
        );
        expect(imageBounds.size, heroBounds.size);

        await tester.scrollUntilVisible(
          find.text('Trouvez le bon professionnel, au bon moment.'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'width: $width');

        await tester.scrollUntilVisible(
          find.text('Plombier'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        final renderedAssets = tester
            .widgetList<Image>(find.byType(Image))
            .map((image) => image.image)
            .whereType<AssetImage>()
            .map((image) => image.assetName)
            .toSet();
        expect(
          renderedAssets,
          containsAll([
            'assets/images/categories/plombier.jpg',
            'assets/images/categories/electricien.jpg',
            'assets/images/categories/menuisier.jpg',
            'assets/images/categories/macon.jpg',
            'assets/images/categories/peintre.jpg',
            'assets/images/categories/reparateur.jpg',
            'assets/images/categories/nettoyage.jpg',
          ]),
          reason: 'all seven category photos should be rendered at width: $width',
        );
        expect(tester.takeException(), isNull, reason: 'width: $width');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('public landing category opens Explore with its trade filter', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PublicLandingScreen(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => Scaffold(
            body: Text(
              'explore:${state.uri.queryParameters['metier']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme(),
        routerConfig: router,
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Plombier'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Plombier'));
    await tester.pumpAndSettle();

    expect(find.text('explore:plombier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public explore displays categories without professional data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: const PublicExploreScreen(initialQuery: 'Une fuite sous l’évier'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Explorez les métiers.'), findsOneWidget);
    expect(find.textContaining('Une fuite sous l’évier'), findsOneWidget);
    expect(find.text('Plombier'), findsOneWidget);
    expect(
      find.text('Les profils sont accessibles après connexion.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
