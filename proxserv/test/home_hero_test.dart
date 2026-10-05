import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxserv/core/theme/app_theme.dart';
import 'package:proxserv/data/models/enums.dart';
import 'package:proxserv/presentation/widgets/home_hero.dart';

void main() {
  testWidgets('Home editorial surfaces render in dark mode', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    for (final width in [390.0, 1280.0]) {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: ListView(
              children: [
                HomeHero(
                  searchController: controller,
                  onSearchChanged: (_) {},
                  onNeedSelected: (_, _) {},
                  onExplore: () {},
                ),
                const HomeFinalCta(onExplore: _noop),
                const HomeEditorialBand(
                  visualFirst: true,
                  icon: Icons.location_on_outlined,
                  title: 'Professionals nearby',
                  body: 'Check service areas and real availability.',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'width: $width');
      expect(find.text('What service do you need?'), findsOneWidget);
      final heroImage = tester.widget<Image>(
        find.byKey(const ValueKey('home-hero-image')),
      );
      expect(
        (heroImage.image as AssetImage).assetName,
        'assets/images/hero/hero_home.jpg',
      );
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('HomeHero stays within mobile, tablet and desktop widths', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var selectedMetier = Metier.autre;

    for (final width in [360.0, 390.0, 768.0, 1024.0, 1280.0]) {
      tester.view
        ..physicalSize = Size(width, 1000)
        ..devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: HomeHero(
                    searchController: controller,
                    onSearchChanged: (_) {},
                    onNeedSelected: (_, metier) => selectedMetier = metier,
                    onExplore: () {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: HomeFinalCta(onExplore: () {}),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: HomeEditorialBand(
                    visualFirst: width >= 768,
                    icon: Icons.location_on_outlined,
                    title: 'Professionals nearby',
                    body: 'Check service areas and real availability.',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'width: $width');
      expect(find.text('What service do you need?'), findsOneWidget);
      final heroImage = tester.widget<Image>(
        find.byKey(const ValueKey('home-hero-image')),
      );
      expect(
        (heroImage.image as AssetImage).assetName,
        'assets/images/hero/hero_home.jpg',
      );
      final cta = find.text('Explore professionals');
      expect(cta, findsOneWidget, reason: 'width: $width');
      expect(find.text('Find a professional'), findsOneWidget);
      await tester.ensureVisible(find.text('Water leak'));
      await tester.tap(find.text('Water leak'));
      expect(selectedMetier, Metier.plombier, reason: 'width: $width');
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void _noop() {}
